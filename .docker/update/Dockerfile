FROM alpine:latest

ARG USER_ID
ARG GROUP_ID

RUN apk update && apk add --no-cache git curl

COPY --chmod=0755 entrypoint.sh /usr/local/bin/

RUN addgroup -g "${GROUP_ID}" update && \
    adduser -D -u "${USER_ID}" -G update update

ENTRYPOINT [ "entrypoint.sh" ]