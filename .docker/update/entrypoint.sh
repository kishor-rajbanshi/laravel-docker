#!/bin/sh

set -e

version="$1"
installation_dir="/app"
source_dir="/tmp/laravel-docker-compose"
repo_url="https://github.com/kishor-rajbanshi/laravel-docker-compose.git"

entrypoint_log() {
	if [ -z "${UPDATE_ENTRYPOINT_QUIET_LOGS:-}" ]; then
		printf "\r \r"
		echo "$@"
	fi
}

error() {
	entrypoint_log "error: $@"
	exit 1
}

spinner() {
	while :; do
		for c in '|' '/' '-' '\'; do
			printf "\r%s" "$c"
			sleep 0.1
		done
	done
}

catch() {
	if [ -z "$trapped" ]; then
		trapped="$1"
	else
		trapped="$1 $trapped"
	fi

	remove_container="curl -s -X DELETE --unix-socket /var/run/docker.sock http://localhost/containers/$(hostname)?force=true"

	trap "[ \"\$?\" -ne 0 ] && rm -rf $trapped; $remove_container" EXIT
	trap "rm -rf $trapped; $remove_container" HUP INT QUIT TERM
}

merge_env_files() {
	src_file="$1"
	dst_file="$2"

	ensure_empty_last_line() {
		last_line=$(tail -n1 "$1")
		last_byte=$(tail -c1 "$1")

		if [ -n "$last_line" ]; then
			if [ "$last_byte" != "$(printf '\n')" ]; then
				echo -e "\n" >>"$1"
			fi

			if [ "$last_byte" = "$(printf '\n')" ]; then
				echo >>"$1"
			fi
		fi
	}

	ensure_empty_last_line "$dst_file"

	while IFS= read -r line || [ -n "$line" ]; do
		if [ -z "$line" ]; then
			ensure_empty_last_line "$dst_file"
			continue
		fi

		key="${line%%=*}"

		if ! grep -Eq "^${key}=" "$dst_file"; then
			echo "$line" >>"$dst_file"
		fi
	done <"$src_file"

	sed -i 's/\(.*DB_HOST=\).*/\1db/' "$dst_file"

	if grep -q '^DB_CONNECTION=sqlite' "$dst_file"; then
		sed -i 's/^[[:space:]]*DB_DATABASE=/# &/' "$dst_file"
	fi
}

spinner &
spinner_pid=$!

catch "container"

if [ "$#" -gt 1 ]; then
	error "Too many arguments; only one allowed."
fi

if [ ! -e "$installation_dir" ]; then
	error "Installation directory not mounted"
fi

if [ ! -d "$installation_dir" ]; then
	error "Installation directory not a directory"
fi

if [ ! -w "$installation_dir" ]; then
	error "Installation directory not writable"
fi

if [ -e "$installation_dir/.docker" ]; then
	if [ ! -d "$installation_dir/.docker" ]; then
		error ".docker not a directory"
	fi
	if [ ! -r "$installation_dir/.docker" ]; then
		error ".docker directory not readable"
	fi
	if [ ! -w "$installation_dir/.docker" ]; then
		error ".docker directory not writable"
	fi
fi

if [ -e "${installation_dir}/compose.yml" ]; then
	if [ ! -f "$installation_dir/compose.yml" ]; then
		error "compose.yml not a file"
	fi
	if [ ! -r "$installation_dir/compose.yml" ]; then
		error "compose.yml file not readable"
	fi
	if [ ! -w "$installation_dir/compose.yml" ]; then
		error "compose.yml file not writable"
	fi
fi

if [ -e "${installation_dir}/.env.example" ]; then
	if [ ! -f "${installation_dir}/.env.example" ]; then
		error ".env.example not a file"
	fi
	if [ ! -r "${installation_dir}/.env.example" ]; then
		error ".env.example file not readable"
	fi
	if [ ! -w "${installation_dir}/.env.example" ]; then
		error ".env.example file not writable"
	fi
fi

if [ -e "${installation_dir}/.env" ]; then
	if [ ! -f "${installation_dir}/.env" ]; then
		error ".env not a file"
	fi
	if [ ! -r "${installation_dir}/.env" ]; then
		error ".env file not readable"
	fi
	if [ ! -w "${installation_dir}/.env" ]; then
		error ".env file not writable"
	fi
fi

rm -rf "$source_dir"

if ! git clone "$repo_url" "$source_dir" >/dev/null 2>&1; then
	error "Could not connect to the repository; verify your internet connection and try again"
fi

if [ -n "$version" ]; then
	version_prefix=$(printf "%s" "$version" | sed 's/\./\\./g')

	semver=$(
		git -C "$source_dir" tag --list "*${version}*" |
			grep -E "^(v?${version_prefix}([0-9]*\.[0-9]*|[0-9]*)(\.|$))" |
			sort -V |
			tail -n1
	)

	if ! git -C "$source_dir" checkout "$version" >/dev/null 2>&1; then
		if ! git -C "$source_dir" checkout "$semver" >/dev/null 2>&1; then
			error "Version \"$version\" not found"
		fi
	fi
fi

version=$(
	git -C "$source_dir" describe --exact-match --tags 2>/dev/null ||
		git -C "$source_dir" rev-parse HEAD
)

if [ -e "${installation_dir}/.docker/VERSION" ]; then
	if [ -f "${installation_dir}/.docker/VERSION" ] && [ -r "${installation_dir}/.docker/VERSION" ]; then
		current_version="$(cat "${installation_dir}/.docker/VERSION")"
		if [ "$version" = "$current_version" ]; then
			entrypoint_log "Version $version is already up-to-date"
			exit 0
		fi
	fi
fi

echo "$version" >"${source_dir}/.docker/VERSION"

chown update:update "$source_dir"

catch "${installation_dir}/.docker"
cp -rf "${source_dir}/.docker/." "${installation_dir}/.docker"

catch "${installation_dir}/compose.yml"
cp -f "${source_dir}/compose.yml" "${installation_dir}/compose.yml"

if [ -e "${installation_dir}/.env.example" ]; then
	merge_env_files "${source_dir}/.env.example" "${installation_dir}/.env.example"
else
	catch "${installation_dir}/.env.example"
	cp "${source_dir}/.env.example" "${installation_dir}/.env.example"
fi

if [ -e "${installation_dir}/.env" ]; then
	merge_env_files "${source_dir}/.env.example" "${installation_dir}/.env"
else
	catch "${installation_dir}/.env"
	cp "${installation_dir}/.env.example" "${installation_dir}/.env"
fi

kill $spinner_pid 2>/dev/null

entrypoint_log "Version $version updated successfully"
