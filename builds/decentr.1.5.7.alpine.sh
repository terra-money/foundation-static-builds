#!/bin/sh -x

BASEDIR=$(dirname "$0")
DOCKER_DIR="${BASEDIR}/.."
IMAGE="alpine"
NAME="decentr"
REPO="Decentr-net/decentr"
TAG="1.5.7"
GO_VERSION="1.16"
    
# BUILD_COMMAND=$(cat <<-'EOT'
#     go install \
#         -mod=readonly \
#         -tags "netgo ledger muslc" \
#         -ldflags '\
#             -X github.com/cosmos/cosmos-sdk/version.Name=decentr \
#             -X github.com/cosmos/cosmos-sdk/version.AppName=decentrd \
#             -X github.com/cosmos/cosmos-sdk/version.Version=${VERSION} \
#             -X github.com/cosmos/cosmos-sdk/version.Commit=${COMMIT} \
#             -w -s -linkmode=external -extldflags \"-Wl,-z,muldefs -static -lgcompat\" \
#         ' \
#         -trimpath \
#     ./cmd/decentrd 
# EOT
# )

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
    --build-arg "BUILD_COMMAND=CGO_ENABLED=0 make install" \
    --build-arg "BUILD_TAGS=netgo ledger muslc" \
    --build-arg "COSMOS_BUILD_OPTIONS=" \
    --build-arg "GIT_TAG=v${TAG}" \
    --build-arg "GIT_REPO=${REPO}" \
    --build-arg "GO_VERSION=${GO_VERSION}" \
    --build-arg "MIMALLOC_VERSION=" \
    --build-arg "LDFLAGS=-w -s -linkmode=external -extldflags \"-Wl,-z,muldefs -static\"" \
    $@
