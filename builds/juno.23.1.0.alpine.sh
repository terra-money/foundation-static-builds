#!/bin/sh -x

BASEDIR=$(dirname "$0")
DOCKER_DIR="${BASEDIR}/.."
IMAGE="alpine"
NAME="juno"
REPO="CosmosContracts/juno"
TAG="23.1.0"
GO_VERSION="1.22.2"

cd "${DOCKER_DIR}"
docker buildx build "." -f "${IMAGE}.Dockerfile" \
    --load \
    --progress plain \
    --tag "terraformlabs/${NAME}:${TAG}" \
    --platform "linux/amd64" \
    --build-arg "OS=linux" \
    --build-arg "ARCH=amd64" \
    --build-arg "APP_NAME=${NAME}" \
    --build-arg "BIN_NAME=${NAME}d" \
    --build-arg "DENOM=uatom" \
    --build-arg "BUILD_COMMAND=make install" \
    --build-arg "BUILD_TAGS=netgo ledger muslc" \
    --build-arg "COSMOS_BUILD_OPTIONS=" \
    --build-arg "GIT_TAG=v${TAG}" \
    --build-arg "GIT_REPO=${REPO}" \
    --build-arg "GO_VERSION=${GO_VERSION}" \
    --build-arg "LDFLAGS=-w -s -linkmode=external -extldflags \"-Wl,-z,muldefs -static\"" \
    --build-arg "MIMALLOC_VERSION=" \
    $@
