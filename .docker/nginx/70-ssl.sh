#!/bin/sh

set -e

ssl_dir="/etc/nginx/ssl"
map_file="/etc/acme/map"
me=$(basename "$0")

cmd_log() {
    if [ -z "${NGINX_CMD_QUIET_LOGS:-}" ]; then
        echo "$@"
    fi
}

if [ "${ACME_ENABLED}" = "false" ] && [ -z "$(ls -A "$ssl_dir")" ]; then
    cmd_log "${me}: info: $ssl_dir is empty, skipping configuration"
    exit 0
fi

cmd_log "${me}: info: Will attempt to perform configuration"

. /opt/venv/bin/activate

json_conf_file=$(mktemp)

if [ -f "$map_file" ]; then
    : >"$map_file"
fi

crossplane parse "$NGINX_MAIN_CONF_FILE" -o "$json_conf_file"

jq -c '.config[].parsed[] | select(.directive == "server")' "$json_conf_file" |
    while read -r server; do

        server_name=$(
            echo "$server" |
                jq -r '.block[] | select(.directive == "server_name") | .args | join(" ")'
        )

        if [ "$server_name" = "_" ]; then
            cmd_log "${me}: info: server_name is '$server_name', skipping configuration"
            continue
        fi

        include_no_ssl=$(
            echo "$server" |
                jq -r '[.block[] | select(.directive=="include" and .args[0] == "*no_ssl")] | any'
        )

        if [ "$include_no_ssl" = true ]; then
            cmd_log "${me}: info: *no_ssl included for '$server_name', skipping configuration"
            continue
        fi

        cmd_log "${me}: info: Searching for SSL certificate associated with '$server_name'"

        for cert_file in "$ssl_dir"/*; do
            cert_file_domains=$(
                openssl x509 -in "$cert_file" -noout -text 2>/dev/null |
                    awk '/X509v3 Subject Alternative Name/ {
                        getline
                        gsub(/^ +| +$/, "")
                        gsub(/DNS:/, "")
                        gsub(/, */, " ")
                        print
                    }' | awk '{$1=$1; print}' | sort
            )

            if [ -z "$cert_file_domains" ]; then
                continue
            fi

            cert_file_pubkey="$(openssl x509 -in "$cert_file" -pubkey -noout)"

            cert_file_has_server_name=1

            for domain in "$server_name"; do
                case " $cert_file_domains " in
                *" $domain "*) ;;
                *)
                    cert_file_has_server_name=0
                    break
                    ;;
                esac
            done

            if [ "$cert_file_has_server_name" -ne 1 ]; then
                continue
            fi

            cmd_log "${me}: info: SSL certificate for '$server_name' found at ${cert_file}, proceeding with configuration"

            cmd_log "${me}: info: Searching for SSL key associated with $cert_file"

            found_key_file=0

            for key_file in "$ssl_dir"/*; do
                key_file_pubkey="$(openssl pkey -in "$key_file" -pubout -outform PEM 2>/dev/null || true)"

                if [ "x$cert_file_pubkey" = "x$key_file_pubkey" ]; then
                    found_key_file=1
                    break
                fi
            done

            if [ "$found_key_file" -eq 0 ]; then
                cmd_log "${me}: warning: Key file associated with $cert_file not found, skipping configuration"
                continue
            fi

            cmd_log "${me}: info: SSL key for $cert_file found at ${key_file}, proceeding with configuration"

            updated_json_conf_file=$(mktemp)

            ssl_port=$(
                echo "$server" |
                    jq -r '
                        .block[] |
                        select(.directive == "include" and (.args[0] | test("^ssl_port\\*\\d+"))) |
                        .args[0] |
                        sub("^ssl_port\\*"; "")
                    '
            )

            if [ -n "$ssl_port" ]; then
                cmd_log "${me}: info: Using ssl port '$ssl_port' for '$server_name'"
            fi

            jq \
                --argjson server "$server" \
                --arg cert_file "$cert_file" \
                --arg key_file "$key_file" \
                --arg NGINX_SSL_PORT "${NGINX_SSL_PORT}" \
                --arg ssl_port "$ssl_port" '
                .config |= map(
                    if any(.parsed[]; .block == $server.block) then
                        .parsed |= ([{
                            directive: "server",
                            args: [],
                            block: (
                                ($server.block | map(select(.directive == "listen" and (.args[0] | startswith("unix:") | not)))) +
                                ($server.block | map(select(.directive == "server_name") | {directive, args})) +
                                [{directive: "return", args: ["301", "https://$host$request_uri"]}]
                            )
                        }] + .)
                    else
                        .
                    end
                ) 
                | .config |= map(
                    .parsed |= map(
                        if .block == $server.block then
                            .block |= (
                                map(
                                    if .directive == "listen" then
                                        if (.args[0] | startswith("unix:")) then
                                            .
                                        elif (.args[0] | test("^[0-9]+$")) then
                                            .args[0] = ($ssl_port | select(length > 0) // $NGINX_SSL_PORT)
                                        else
                                            .args[0] as $a0 |
                                            ($a0 | split(":")) as $parts |
                                            ($parts | if length>0 then .[-1] else "" end | test("^[0-9]+$")) as $last_is_num |
                                            if $last_is_num then
                                                .args[0] = (($parts[0:-1] | join(":")) + ":" + ($ssl_port | select(length > 0) // $NGINX_SSL_PORT))
                                            else
                                                .args[0] = ($a0 + ":" + ($ssl_port | select(length > 0) // $NGINX_SSL_PORT))
                                            end
                                        end
                                        | .args = [.args[0]] + ((.args[1:] // []) | map(select(. != "ssl")) + ["ssl"])
                                    elif .directive == "ssl_certificate" then
                                        .args = [$cert_file]
                                    elif .directive == "ssl_certificate_key" then
                                        .args = [$key_file]
                                    else
                                        .
                                    end
                                )
                                +
                                (if any(.[]; .directive == "listen") | not then
                                    [{ directive: "listen", args: [($ssl_port | select(length > 0) // $NGINX_SSL_PORT), "ssl"] }]
                                else [] end)
                                +
                                (if any(.[]; .directive == "ssl_certificate") | not then
                                    [{"directive": "ssl_certificate", "args": [$cert_file]}]
                                else [] end)
                                +
                                (if any(.[]; .directive == "ssl_certificate_key") | not then
                                    [{"directive": "ssl_certificate_key", "args": [$key_file]}]
                                else [] end)
                                +
                                (if any(.[]; .directive == "ssl_protocols") | not then
                                    [{"directive": "ssl_protocols", "args": ["TLSv1.2", "TLSv1.3"]}]
                                else [] end)
                                +
                                (if any(.[]; .directive == "ssl_ciphers") | not then
                                    [{"directive": "ssl_ciphers", "args": ["HIGH:!aNULL:!MD5"]}]
                                else [] end)
                            )
                        else
                            .
                        end
                    )
                )' <"$json_conf_file" >"$updated_json_conf_file"

            mv -f "$updated_json_conf_file" "$json_conf_file"

            continue 2
        done

        if [ "${ACME_ENABLED}" = "true" ]; then
            root=$(echo "$server" | jq -r '.block[] | select(.directive=="root") | .args[0]')
            echo "$server_name => $root" >>"$map_file"
        fi

        cmd_log "${me}: warning: Certificate/Key file associated with '$server_name' not found, skipping configuration"
    done

crossplane build --force "$json_conf_file"
rm -rf "$json_conf_file"

cmd_log "${me}: info: Configuration complete"
