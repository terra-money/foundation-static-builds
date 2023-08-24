#!/bin/sh -x

BASEDIR=$(dirname "$0")
DOCKER_DIR="${BASEDIR}/.."
IMAGE="arch"
NAME="terra"
REPO="terra-money/core"

cd "${DOCKER_DIR}"
docker buildx build "." -f "${IMAGE}.Dockerfile" \
    --load \
    --tag "${NAME}:example" \
    --platform "linux/amd64" \
    --build-arg "OS=linux" \
    --build-arg "ARCH=amd64" \
    --build-arg "APP_NAME=${NAME}" \
    --build-arg "BIN_NAME=${NAME}d" \
    --build-arg "BUILD_COMMAND=make install" \
    --build-arg "BUILDPLATFORM=linux/amd64" \
    --build-arg "BUILD_TAGS=muslc" \
    --build-arg "COSMOS_BUILD_OPTIONS=nostrip" \
    --build-arg "GIT_TAG=v2.4.1" \
    --build-arg "GIT_REPO=${REPO}" \
    --build-arg "GO_VERSION=1.20.8" \
    --build-arg "MIMALLOC_VERSION=" \
    --build-arg "LDFLAGS=" \
    $@
    # --build-arg "LDFLAGS=-extldflags \"-Wl,-z,muldefs -static\"" \
    # --build-arg "CHAIN_REGISTRY_NAME=${NAME}" \
    
