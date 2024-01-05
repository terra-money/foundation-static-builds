#!/bin/sh -x

BASEDIR=$(dirname "$0")
DOCKER_DIR="${BASEDIR}/.."
DISTRO="alpine"
NAME="chihuahua"
REPO="ChihuahuaChain/chihuahua"
TAG="6"
GO_VERSION="1.20"
DISTRO_VERSION="3.18"

cd "${DOCKER_DIR}"
docker buildx build "." -f "${DISTRO}.Dockerfile" \
    --load \
    --progress plain \
    --tag "terraformlabs/${NAME}:${TAG}" \
    --platform "linux/amd64" \
    --build-arg "OS=linux" \
    --build-arg "ARCH=amd64" \
    --build-arg "APP_NAME=${NAME}" \
    --build-arg "BIN_NAME=${NAME}d" \
    --build-arg "BUILD_COMMAND=CGO_ENABLED=0 make install" \
    --build-arg "BUILD_TAGS=netgo ledger muslc" \
    --build-arg "COSMOS_BUILD_OPTIONS=" \
    --build-arg "GIT_TAG=v${TAG}" \
    --build-arg "GIT_REPO=${REPO}" \
    --build-arg "GO_VERSION=${GO_VERSION}" \
    --build-arg "MIMALLOC_VERSION=" \
    --build-arg "LDFLAGS=-w -s -linkmode=external -extldflags \"-Wl,-z,muldefs -static\"" \
    $@
