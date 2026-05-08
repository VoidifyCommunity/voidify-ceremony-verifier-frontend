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
ENV GIT_COMMIT_HASH=c53c84477793e04895b16a2d837c1fa757e8673b

RUN mkdir /app/
WORKDIR /app

RUN git init && \
    git remote add origin $GIT_REPOSITORY && \
    git fetch --depth 1 origin $GIT_COMMIT_HASH && \
    git checkout $GIT_COMMIT_HASH

RUN npm ci --ignore-scripts

RUN npx nuxt prepare

RUN npm run generate

COPY reference/ /app/reference/
RUN test -s /app/reference/style.DpOu6hTD.css

ENV TARGET_BUILD_ID=96ee26d3-8b44-4426-8e30-26e6fb08a629
ENV TARGET_BUILD_TS=1777566778849
ENV TARGET_CSS_HASH=DpOu6hTD

RUN cd .output/public && \
    NEW_BUILD_ID=$(basename _nuxt/builds/meta/*.json .json) && \
    NEW_CSS_HASH=$(basename _nuxt/style.*.css .css | sed 's|style\.||') && \
    for entry in 'index.html:1777566799930' '200.html:1777566799929' '404.html:1777566799930'; do \
        f=${entry%%:*} ; \
        target_html_ts=${entry##*:} ; \
        html_ts=$(grep -oE '[0-9]{13}' "$f" | head -1) ; \
        sed -i \
            -e "s|$NEW_BUILD_ID|$TARGET_BUILD_ID|g" \
            -e "s|$html_ts|$target_html_ts|g" \
            -e "s|style\\.$NEW_CSS_HASH\\.css|style.$TARGET_CSS_HASH.css|g" \
            "$f" ; \
    done && \
    rm _nuxt/style.*.css && \
    cp /app/reference/style.${TARGET_CSS_HASH}.css _nuxt/style.${TARGET_CSS_HASH}.css && \
    printf '{"id":"%s","timestamp":%s}' "$TARGET_BUILD_ID" "$TARGET_BUILD_TS" \
        > _nuxt/builds/latest.json && \
    rm -f _nuxt/builds/meta/*.json && \
    printf '{"id":"%s","timestamp":%s,"prerendered":[]}' "$TARGET_BUILD_ID" "$TARGET_BUILD_TS" \
        > _nuxt/builds/meta/${TARGET_BUILD_ID}.json

RUN ipfs add --cid-version 1 --quieter --only-hash --recursive ./.output/public > ipfs_hash.txt
RUN cat ipfs_hash.txt

RUN printf '#!/bin/sh\nipfs --api /ip4/`getent ahostsv4 host.docker.internal | grep STREAM | head -n 1 | cut -d \  -f 1`/tcp/5001 add --cid-version 1 -r ./.output/public' >> entrypoint.sh
RUN chmod u+x entrypoint.sh

ENTRYPOINT [ "./entrypoint.sh" ]
