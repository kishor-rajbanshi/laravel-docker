FROM neilpang/acme.sh

ARG USER_ID
ARG GROUP_ID

COPY --chmod=0755 \
    cmd.sh \
    ssl.sh \
    notify.sh \
    healthcheck.sh \
    /usr/local/bin/

RUN addgroup -g "${GROUP_ID}" acme && \
    adduser -D -u "${USER_ID}" -G acme acme

CMD [ "cmd.sh" ]
