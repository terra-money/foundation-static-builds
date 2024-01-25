ARG GO_VERSION="1.20"

################################################################################
FROM golang:${GO_VERSION}-alpine as base

# NOTE: add libusb-dev to run with LEDGER_ENABLED=true
RUN set -eu && \
    apk update && \
    apk add --no-cache \
    ca-certificates \
    linux-headers \
    build-base \
    musl-dev \
    bash \
    bison \
    curl \
    gcompat \
    git 

COPY ./bin/install-mimalloc ./bin/install-wasmvm ./bin/install-rocksdb /usr/local/bin/

################################################################################
FROM base as builder

ARG APP_NAME="terra"
ARG BIN_NAME="${APP_NAME}d"
ARG COSMOS_BUILD_OPTIONS="nostrip"
ARG DENOM
ARG GIT_TAG="v2.4.1"
ARG GIT_REPO="terra-money/core"
ARG MIMALLOC_VERSION
ARG ROCKSDB_VERSION
ARG GO_VERSION

ENV MIMALLOC_VERSION=${MIMALLOC_VERSION}
# install mimalloc if version is specified
RUN set -eu && \
    if [ -n "${MIMALLOC_VERSION}" ]; then install-mimalloc "${MIMALLOC_VERSION}"; fi

ENV ROCKSDB_VERSION=${ROCKSDB_VERSION}
# install rocksdb if version is specified
RUN set -eu && \
    if [ -n "${ROCKSDB_VERSION}" ]; then install-rocksdb "${ROCKSDB_VERSION}"; fi

# download dependencies to cache as layer
WORKDIR ${GOPATH}/src/app

ENV GIT_TAG=${GIT_TAG} \
    GIT_REPO=${GIT_REPO}

SHELL [ "/bin/bash", "-c" ]

RUN set -e && \
    git clone -b ${GIT_TAG} https://github.com/${GIT_REPO}.git ./ && \
    # export GO_MOD_VERSION="$(awk '/^go /{print $2}' go.mod)" && \
    # if [[ "${GO_VERSION}" != "${GO_MOD_VERSION}"* ]]; then \
    #     /bin/bash < <(curl -sSL https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer) && \
    #     source ${HOME}/.gvm/scripts/gvm && \
    #     gvm install go${GO_MOD_VERSION} && \
    #     gvm use go${GO_MOD_VERSION}; \
    # fi && \ 
    go mod download -x || true

# download wasmvm if version is specified
RUN set -ux && \
    WASMVM_VERSION="$(go list -m github.com/CosmWasm/wasmvm | cut -d ' ' -f 2)" && \
    [ -n "${WASMVM_VERSION}" ] && install-wasmvm "${WASMVM_VERSION}" || true

# build the binary
ARG BUILD_COMMAND="make install"
ARG BUILD_TAGS="netgo,ledger,muslc"
ARG BUILD_TAGS=""
ARG LDFLAGS='-w -s -linkmode external -extldflags "-Wl,-z,muldefs -static"'
#ARG LDFLAGS="-extldflags '-L/go/src/mimalloc/build -lmimalloc -Wl,-z,muldefs -static'"
ARG CHECK_STATICALLY="true"

ENV APP_NAME=${APP_NAME} \
    BUILD_COMMAND=${BUILD_COMMAND} \
    DENOM=${DENOM} \
    LDFLAGS=${LDFLAGS} \
    LEDGER_ENABLED=false \
    LINK_STATICALLY=true

RUN --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=cache,target=/root/go/pkg/mod \
    set -eux && \
    export COMMIT=GIT_COMMIT="$(git log -1 --format='%h')" && \
    export VERSION=GIT_VERSION="$(git describe --tags --dirty --always)" && \
    export DENOM=${DENOM:-"u$(echo ${APP_NAME} | head -c 4)"} && \
    export GOWORK=off && \
    ls -al && \
    eval ${BUILD_COMMAND}

# verify static binary
RUN set -x && \
    file ${GOPATH}/bin/${BIN_NAME} && \
    if [ "${CHECK_STATICALLY}" = "true" ]; then \
        echo "Ensuring binary is statically linked ..." && \
        (file ${GOPATH}/bin/${BIN_NAME} | grep "statically linked"); \
    fi

################################################################################
FROM --platform=${BUILDPLATFORM} alpine:latest as prod

# build args passed down to env var

ARG APP_NAME="terra"
ARG BIN_NAME="${APP_NAME}d"
ARG CHAIN_REGISTRY_NAME

ENV APP_NAME=${APP_NAME} \
    BIN_NAME=${BIN_NAME} \
    CHAIN_REGISTRY_NAME=${CHAIN_REGISTRY_NAME}

# copy binary and entrypoint
COPY --from=builder /go/bin/${BIN_NAME} /usr/local/bin/${BIN_NAME}
COPY ./bin/entrypoint.sh /usr/local/bin/

# install jq and create user
RUN set -eux && \   
    apk update && \
    apk add --no-cache bash curl jq && \
    addgroup -g 1000 ${APP_NAME} && \
    adduser -u 1000 -G ${APP_NAME} -D -s /bin/bash -h /home/${APP_NAME} ${APP_NAME} && \
    ln -s /usr/local/bin/${BIN_NAME} /usr/local/bin/chaind

# setup execution environment
USER ${APP_NAME}
SHELL [ "/bin/bash" ]
WORKDIR /home/${APP_NAME}
ENTRYPOINT [ "entrypoint.sh" ]
CMD ["chaind", "start"]



