ARG OS=linux
ARG ARCH=amd64
ARG BUILDPLATFORM=${OS}/${ARCH}
ARG DISTRO_VERSION="2023091804"
ARG BASE_IMAGE="binhex/arch-base:${DISTRO_VERSION}"

# ################################################################################
FROM --platform=${BUILDPLATFORM} ${BASE_IMAGE} as base

ARG OS
ARG ARCH
ARG GO_VERSION="1.20.8"

# # NOTE: add libusb-dev to run with LEDGER_ENABLED=true
RUN set -eu & \
    pacman -Syyu --noconfirm linux-headers base-devel glibc git && \
    curl -sSL https://go.dev/dl/go${GO_VERSION}.${OS}-${ARCH}.tar.gz | \
    tar -C / -xz && \
    ln -s /go/bin/go /usr/local/bin/go

COPY ./bin/install-mimalloc ./bin/install-wasmvm /usr/local/bin/

# ################################################################################
FROM base as builder

ARG APP_NAME="terra"
ARG BIN_NAME="${APP_NAME}d"
ARG BUILD_COMMAND="make install"
ARG BUILD_TAGS="muslc"
ARG COSMOS_BUILD_OPTIONS="nostrip"
ARG GIT_TAG="v2.4.1"
ARG GIT_REPO="terra-money/core"
# ARG LDFLAGS="-extldflags '-L/go/src/mimalloc/build -lmimalloc -Wl,-z,muldefs -static'"
ARG LDFLAGS='-extldflags "-Wl,-z,muldefs -static"'
ARG MIMALLOC_VERSION
# ARG MIMALLOC_VERSION="v2.1.2"

ENV GOPATH=/go
ENV MIMALLOC_VERSION=${MIMALLOC_VERSION}
# install mimalloc if version is specified
RUN set -eu && \
    if [ -n "${MIMALLOC_VERSION}" ]; then install-mimalloc "${MIMALLOC_VERSION}"; fi

# download dependencies to cache as layer
WORKDIR ${GOPATH}/src/app

ENV GIT_TAG=${GIT_TAG} \
    GIT_REPO=${GIT_REPO}

RUN set -eu && \
    git clone -b ${GIT_TAG} https://github.com/${GIT_REPO}.git ./ && \
    go mod download

# download wasmvm if version is specified
RUN set -ux && \
    WASMVM_VERSION="$(go list -m github.com/CosmWasm/wasmvm | cut -d ' ' -f 2)" && \
    [ -n "${WASMVM_VERSION}" ] && install-wasmvm "${WASMVM_VERSION}" || true

# build the binary
ENV APP_NAME=${APP_NAME} \
    BUILD_TAGS=${BUILD_TAGS} \
    DENOM=${DENOM} \
    LDFLAGS=${LDFLAGS} \
    LEDGER_ENABLED=false \
    LINK_STATICALLY=true

RUN set -eux && \
    export COMMIT=GIT_COMMIT="$(git log -1 --format='%h')" && \
    export VERSION=GIT_VERSION="$(git describe --tags --dirty --always)" && \
    export DENOM=${DENOM:-"u$(echo ${APP_NAME} | head -c 4)"} && \
    ${BUILD_COMMAND}

# verify static binary
RUN set -x && \
    file ${GOPATH}/bin/${BIN_NAME} && \
    echo "Ensuring binary is statically linked ..." && \
    (file ${GOPATH}/bin/${BIN_NAME} | grep "statically linked")

# ################################################################################
FROM --platform=${BUILDPLATFORM} ${BASE_IMAGE} as prod

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
    pacman -Syyu --noconfirm jq && \
    groupadd -g 1000 ${APP_NAME} && \
    useradd -u 1000 -g ${APP_NAME} -s /bin/bash -d /home/${APP_NAME} ${APP_NAME} && \
    ln -s /usr/local/bin/${BIN_NAME} /usr/local/bin/chaind

# setup execution environment
USER ${APP_NAME}
SHELL [ "/bin/bash" ]
WORKDIR /home/${APP_NAME}
ENTRYPOINT [ "entrypoint.sh" ]
CMD ["chaind", "start"]


