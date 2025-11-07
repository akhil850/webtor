# syntax=docker/dockerfile:1.7

ARG ALPINE_VER="3.22"
ARG GOLANG_VER="1.25-alpine3.22"
ARG NODE_VER="23-alpine3.22"
ARG S6_OVERLAY_VER="3.2.0.2"
ARG S6_VERBOSITY=1

# Webtor services
ARG TORRENT_STORE_COMMIT="9e48304b005475f73a3993d30870c4d3cf71c598"
ARG MAGNET2TORRENT_COMMIT="88c9e8be3241a3a4daa4033bce16462e8b8c1a25"
ARG EXTERNAL_PROXY_COMMIT="06588b7b83443fa6661cc6e8a2b294a8f725046a"
ARG TORRENT_WEB_SEEDER_COMMIT="cb4ff2b10884270563481de980f0ab66ec8dace2"
ARG TORRENT_WEB_SEEDER_CLEANER_COMMIT="dec86fa01f739ef3bcd20e9e1408c22485f93d51"
ARG CONTENT_TRANSCODER_COMMIT="9473e22624e3f79a15ff17aa8b975e5c6f62ec17"
ARG TORRENT_ARCHIVER_COMMIT="5ec51fe299641ca7ed3e5cb19f9a2ab370cca89a"
ARG SRT2VTT_COMMIT="5a18d26bee380d6964e074713be2a4a98b2d54df"
ARG TORRENT_HTTP_PROXY_COMMIT="d08b3921bb193ef863c629b96f1c0b5e00b5fc20"
ARG REST_API_COMMIT="490b6c3f85b7378545a35575b6affd04aca80c55"
ARG WEB_UI_COMMIT="fd5412ec2d84fce840b580d4a5dc2ac706cffd31"

# Nginx deps
ARG NGINX_VERSION="1.29.3"
ARG VOD_MODULE_COMMIT="26f06877b0f2a2336e59cda93a3de18d7b23a3e2"
ARG SECURE_TOKEN_MODULE_COMMIT="24f7b99d9b665e11c92e585d6645ed6f45f7d310"

# ---------------------------
# Common Go build environment
# ---------------------------
FROM golang:$GOLANG_VER AS build-app
ARG TARGETOS TARGETARCH
RUN apk add --no-cache build-base git
RUN git config --global http.version HTTP/1.1
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0
WORKDIR /app
RUN mkdir -p src bin

# Helper: shallow checkout at a commit into a path
# (used inline in each stage)

# ---------------------------
# Services — build per target
# ---------------------------
FROM build-app AS build-torrent-store
ARG TORRENT_STORE_COMMIT TARGETOS TARGETARCH
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0
RUN echo $TORRENT_STORE_COMMIT > /app/bin/torrent-store.commit && \
    git clone --filter=blob:none --depth=1 https://github.com/webtor-io/torrent-store /app/src/torrent-store && \
    cd /app/src/torrent-store && \
    git fetch --depth=1 origin $TORRENT_STORE_COMMIT && git checkout $TORRENT_STORE_COMMIT
RUN --mount=type=cache,target=/root/.cache/go-build --mount=type=cache,target=/go/pkg/mod \
    cd /app/src/torrent-store && \
    go build -ldflags '-w -s -X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=ignore' \
             -trimpath -buildvcs=false -o /app/bin/torrent-store

FROM build-app AS build-magnet2torrent
ARG MAGNET2TORRENT_COMMIT TARGETOS TARGETARCH
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0
RUN echo $MAGNET2TORRENT_COMMIT > /app/bin/magnet2torrent.commit && \
    git clone --filter=blob:none --depth=1 https://github.com/webtor-io/magnet2torrent /app/src/magnet2torrent && \
    cd /app/src/magnet2torrent && \
    git fetch --depth=1 origin $MAGNET2TORRENT_COMMIT && git checkout $MAGNET2TORRENT_COMMIT
RUN --mount=type=cache,target=/root/.cache/go-build --mount=type=cache,target=/go/pkg/mod \
    cd /app/src/magnet2torrent/server && \
    go build -ldflags '-w -s -X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=ignore' \
             -trimpath -buildvcs=false -o /app/bin/magnet2torrent

FROM build-app AS build-external-proxy
ARG EXTERNAL_PROXY_COMMIT TARGETOS TARGETARCH
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0
RUN echo $EXTERNAL_PROXY_COMMIT > /app/bin/external-proxy.commit && \
    git clone --filter=blob:none --depth=1 https://github.com/webtor-io/external-proxy /app/src/external-proxy && \
    cd /app/src/external-proxy && \
    git fetch --depth=1 origin $EXTERNAL_PROXY_COMMIT && git checkout $EXTERNAL_PROXY_COMMIT
RUN --mount=type=cache,target=/root/.cache/go-build --mount=type=cache,target=/go/pkg/mod \
    cd /app/src/external-proxy && \
    go build -ldflags '-w -s' -trimpath -buildvcs=false -o /app/bin/external-proxy

FROM build-app AS build-torrent-web-seeder
ARG TORRENT_WEB_SEEDER_COMMIT TARGETOS TARGETARCH
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0
RUN echo $TORRENT_WEB_SEEDER_COMMIT > /app/bin/torrent-web-seeder.commit && \
    git clone --filter=blob:none --depth=1 https://github.com/webtor-io/torrent-web-seeder /app/src/torrent-web-seeder && \
    cd /app/src/torrent-web-seeder && \
    git fetch --depth=1 origin $TORRENT_WEB_SEEDER_COMMIT && git checkout $TORRENT_WEB_SEEDER_COMMIT
RUN --mount=type=cache,target=/root/.cache/go-build --mount=type=cache,target=/go/pkg/mod \
    cd /app/src/torrent-web-seeder/server && \
    go build -ldflags '-w -s' -trimpath -buildvcs=false -o /app/bin/torrent-web-seeder

FROM build-app AS build-torrent-web-seeder-cleaner
ARG TORRENT_WEB_SEEDER_CLEANER_COMMIT TARGETOS TARGETARCH
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0
RUN echo $TORRENT_WEB_SEEDER_CLEANER_COMMIT > /app/bin/torrent-web-seeder-cleaner.commit && \
    git clone --filter=blob:none --depth=1 https://github.com/webtor-io/torrent-web-seeder-cleaner /app/src/torrent-web-seeder-cleaner && \
    cd /app/src/torrent-web-seeder-cleaner && \
    git fetch --depth=1 origin $TORRENT_WEB_SEEDER_CLEANER_COMMIT && git checkout $TORRENT_WEB_SEEDER_CLEANER_COMMIT
RUN --mount=type=cache,target=/root/.cache/go-build --mount=type=cache,target=/go/pkg/mod \
    cd /app/src/torrent-web-seeder-cleaner && \
    go build -ldflags '-w -s' -trimpath -buildvcs=false -o /app/bin/torrent-web-seeder-cleaner

FROM build-app AS build-content-transcoder
ARG CONTENT_TRANSCODER_COMMIT TARGETOS TARGETARCH
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0
RUN echo $CONTENT_TRANSCODER_COMMIT > /app/bin/content-transcoder.commit && \
    git clone --filter=blob:none --depth=1 https://github.com/webtor-io/content-transcoder /app/src/content-transcoder && \
    cd /app/src/content-transcoder && \
    git fetch --depth=1 origin $CONTENT_TRANSCODER_COMMIT && git checkout $CONTENT_TRANSCODER_COMMIT
RUN --mount=type=cache,target=/root/.cache/go-build --mount=type=cache,target=/go/pkg/mod \
    cd /app/src/content-transcoder && \
    go build -ldflags '-w -s' -trimpath -buildvcs=false -o /app/bin/content-transcoder

FROM build-app AS build-torrent-archiver
ARG TORRENT_ARCHIVER_COMMIT TARGETOS TARGETARCH
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0
RUN echo $TORRENT_ARCHIVER_COMMIT > /app/bin/torrent-archiver.commit && \
    git clone --filter=blob:none --depth=1 https://github.com/webtor-io/torrent-archiver /app/src/torrent-archiver && \
    cd /app/src/torrent-archiver && \
    git fetch --depth=1 origin $TORRENT_ARCHIVER_COMMIT && git checkout $TORRENT_ARCHIVER_COMMIT
RUN --mount=type=cache,target=/root/.cache/go-build --mount=type=cache,target=/go/pkg/mod \
    cd /app/src/torrent-archiver && \
    go build -ldflags '-w -s' -trimpath -buildvcs=false -o /app/bin/torrent-archiver

FROM build-app AS build-srt2vtt
ARG SRT2VTT_COMMIT TARGETOS TARGETARCH
# Enable CGO; Buildx runs this per-arch under QEMU, so it's native for each arch
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=1 CGO_LDFLAGS="-static"
RUN echo $SRT2VTT_COMMIT > /app/bin/srt2vtt.commit && \
    git clone --filter=blob:none --depth=1 https://github.com/webtor-io/srt2vtt /app/src/srt2vtt && \
    cd /app/src/srt2vtt && \
    git fetch --depth=1 origin $SRT2VTT_COMMIT && git checkout $SRT2VTT_COMMIT
RUN --mount=type=cache,target=/root/.cache/go-build --mount=type=cache,target=/go/pkg/mod \
    cd /app/src/srt2vtt && \
    go build -ldflags '-w -s' -trimpath -buildvcs=false -o /app/bin/srt2vtt

FROM build-app AS build-torrent-http-proxy
ARG TORRENT_HTTP_PROXY_COMMIT TARGETOS TARGETARCH
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0
RUN echo $TORRENT_HTTP_PROXY_COMMIT > /app/bin/torrent-http-proxy.commit && \
    git clone --filter=blob:none --depth=1 https://github.com/webtor-io/torrent-http-proxy /app/src/torrent-http-proxy && \
    cd /app/src/torrent-http-proxy && \
    git fetch --depth=1 origin $TORRENT_HTTP_PROXY_COMMIT && git checkout $TORRENT_HTTP_PROXY_COMMIT
RUN --mount=type=cache,target=/root/.cache/go-build --mount=type=cache,target=/go/pkg/mod \
    cd /app/src/torrent-http-proxy && \
    go build -ldflags '-w -s' -trimpath -buildvcs=false -o /app/bin/torrent-http-proxy

FROM build-app AS build-rest-api
ARG REST_API_COMMIT TARGETOS TARGETARCH
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0
RUN echo $REST_API_COMMIT > /app/bin/rest-api.commit && \
    git clone --filter=blob:none --depth=1 https://github.com/webtor-io/rest-api /app/src/rest-api && \
    cd /app/src/rest-api && \
    git fetch --depth=1 origin $REST_API_COMMIT && git checkout $REST_API_COMMIT
RUN --mount=type=cache,target=/root/.cache/go-build --mount=type=cache,target=/go/pkg/mod \
    cd /app/src/rest-api && \
    go build -ldflags '-w -s' -trimpath -buildvcs=false -o /app/bin/rest-api

FROM build-app AS build-web-ui
ARG WEB_UI_COMMIT TARGETOS TARGETARCH
ENV GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0
RUN echo $WEB_UI_COMMIT > /app/bin/web-ui.commit && \
    git clone --filter=blob:none --depth=1 https://github.com/webtor-io/web-ui /app/src/web-ui && \
    cd /app/src/web-ui && \
    git fetch --depth=1 origin $WEB_UI_COMMIT && git checkout $WEB_UI_COMMIT
RUN --mount=type=cache,target=/root/.cache/go-build --mount=type=cache,target=/go/pkg/mod \
    cd /app/src/web-ui && \
    go build -ldflags '-w -s -X google.golang.org/protobuf/reflect/protoregistry.conflictPolicy=ignore' \
             -trimpath -buildvcs=false -o /app/bin/web-ui

# ---------------------------
# Web UI assets (Node)
# ---------------------------
FROM node:$NODE_VER AS build-web-ui-assets
WORKDIR /app
COPY --from=build-web-ui /app/src/web-ui ./
RUN npm install
RUN npm run build

# ---------------------------
# Nginx + modules (per-arch)
# ---------------------------
FROM alpine:$ALPINE_VER AS build-nginx-vod
ARG NGINX_VERSION
ARG VOD_MODULE_COMMIT
ARG SECURE_TOKEN_MODULE_COMMIT
RUN apk add --no-cache curl build-base openssl openssl-dev zlib-dev linux-headers pcre-dev && \
    mkdir nginx nginx-vod-module nginx-secure-token-module && \
    curl -sL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz | tar -C /nginx --strip 1 -xz && \
    curl -sL https://github.com/kaltura/nginx-vod-module/archive/${VOD_MODULE_COMMIT}.tar.gz | tar -C /nginx-vod-module --strip 1 -xz && \
    curl -sL https://github.com/kaltura/nginx-secure-token-module/archive/${SECURE_TOKEN_MODULE_COMMIT}.tar.gz | tar -C /nginx-secure-token-module --strip 1 -xz
WORKDIR /nginx
RUN ./configure --prefix=/usr/local/nginx \
    --add-module=../nginx-vod-module \
    --add-module=../nginx-secure-token-module \
    --with-http_ssl_module \
    --with-file-aio \
    --with-threads \
    --with-cc-opt="-O3" && \
    make && make install && \
    rm -rf /nginx /nginx-vod-module /nginx-secure-token-module && \
    rm -rf /usr/local/nginx/html /usr/local/nginx/conf/*.default

# ---------------------------
# Final runtime image
# ---------------------------
FROM alpine:$ALPINE_VER AS base
ARG S6_OVERLAY_VER
ARG S6_VERBOSITY
ARG TARGETARCH
ENV S6_VERBOSITY=$S6_VERBOSITY

# Install s6 overlay matching the arch
RUN apk --no-cache add curl && \
    case "$TARGETARCH" in \
      amd64)  S6_ARCH=x86_64 ;; \
      arm64)  S6_ARCH=aarch64 ;; \
      *) echo "Unsupported arch: $TARGETARCH" && exit 1 ;; \
    esac && \
    curl -fsSL -o /tmp/s6-overlay-noarch.tar.xz "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VER}/s6-overlay-noarch.tar.xz" && \
    curl -fsSL -o /tmp/s6-overlay-arch.tar.xz   "https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VER}/s6-overlay-${S6_ARCH}.tar.xz" && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-arch.tar.xz && \
    rm -f /tmp/s6-overlay-*.tar.xz

# Runtime deps (fix envsubst/uuidgen)
RUN apk --no-cache add \
      redis ffmpeg ca-certificates openssl pcre zlib \
      gettext util-linux \
      postgresql postgresql-client postgresql-contrib

WORKDIR /app

# Copy built binaries/artifacts
COPY --from=build-torrent-store /app/bin/* ./
COPY --from=build-magnet2torrent /app/bin/* ./
COPY --from=build-external-proxy /app/bin/* ./
COPY --from=build-torrent-web-seeder /app/bin/* ./
COPY --from=build-torrent-web-seeder-cleaner /app/bin/* ./
COPY --from=build-content-transcoder /app/bin/* ./
COPY --from=build-torrent-archiver /app/bin/* ./
COPY --from=build-srt2vtt /app/bin/* ./
COPY --from=build-torrent-http-proxy /app/bin/* ./
COPY --from=build-rest-api /app/bin/* ./
COPY --from=build-web-ui /app/bin/* ./

# App resources
COPY --from=build-web-ui /app/src/web-ui/templates /app/templates
COPY --from=build-web-ui /app/src/web-ui/pub /app/pub
COPY --from=build-web-ui /app/src/web-ui/migrations /app/migrations
COPY --from=build-web-ui-assets /app/assets/dist /app/assets/dist
COPY --from=build-nginx-vod /usr/local/nginx /usr/local/nginx

# Config + s6
COPY etc/webtor /etc/webtor
COPY etc/nginx/conf /usr/local/nginx/conf
COPY s6-overlay /etc/s6-overlay
COPY cont-init.d /etc/cont-init.d

# Ensure s6 scripts are executable
RUN find /etc/s6-overlay -type f \( -name run -o -name up \) -exec chmod +x {} + && \
    find /etc/cont-init.d -type f -exec chmod +x {} +

ENV DOMAIN=http://localhost:8080
EXPOSE 8080
EXPOSE 5432

ENTRYPOINT ["/init"]
