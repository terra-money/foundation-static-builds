ARG GO_VERSION="1.20"
ARG ALPINE_VERSION="3.16"

FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION}
ARG GOOS
ARG GOARCH
ARG GIT_TAG
ARG GIT_REPO

ENV GOOS=$GOOS \ 
    GOARCH=$GOARCH

# NOTE: add libusb-dev to run with LEDGER_ENABLED=true
RUN set -eux &&\
    apk update &&\
    apk add --no-cache \
    ca-certificates \
    linux-headers \
    build-base \
    cmake \
    git

