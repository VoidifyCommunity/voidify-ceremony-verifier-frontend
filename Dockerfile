FROM node:24-bookworm-slim@sha256:03eae3ef7e88a9de535496fb488d67e02b9d96a063a8967bae657744ecd513f2

RUN apt-get update && apt-get install --yes --no-install-recommends \
        wget git apt-transport-https ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g npm@11.6.1

WORKDIR /home/root
RUN wget -qO - https://dist.ipfs.tech/kubo/v0.29.0/kubo_v0.29.0_linux-amd64.tar.gz | tar -xvzf - \
    && cd kubo \
    && ./install.sh \
    && cd .. \
    && rm -rf kubo
RUN ipfs init

ENV GIT_REPOSITORY=https://github.com/VoidifyCommunity/voidify-ceremony-frontend.git
ENV GIT_COMMIT_HASH=9e76ce7cd1154eb61f5afa81a4cee8384e3301fc

RUN mkdir /app/
WORKDIR /app

RUN git init && \
    git remote add origin $GIT_REPOSITORY && \
    git fetch --depth 1 origin $GIT_COMMIT_HASH && \
    git checkout $GIT_COMMIT_HASH

RUN npm ci --ignore-scripts

RUN npx nuxt prepare

RUN npm run generate

RUN ipfs add --cid-version 1 --quieter --only-hash --recursive ./.output/public > ipfs_hash.txt
RUN cat ipfs_hash.txt

RUN printf '#!/bin/sh\nipfs --api /ip4/`getent ahostsv4 host.docker.internal | grep STREAM | head -n 1 | cut -d \  -f 1`/tcp/5001 add --cid-version 1 -r ./.output/public' >> entrypoint.sh
RUN chmod u+x entrypoint.sh

ENTRYPOINT [ "./entrypoint.sh" ]
