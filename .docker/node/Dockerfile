ARG NODE_VERSION

FROM node:"${NODE_VERSION:-current}-alpine"

ARG USER_ID
ARG GROUP_ID

COPY --chmod=0755 \
    permissions.sh \
    node/update-vite-config.sh \
    /usr/local/bin/

RUN permissions.sh node

USER node
