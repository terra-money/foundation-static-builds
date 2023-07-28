ARG GO_VERSION="1.20"
ARG OS_VERESION="3.16"
ARG BUILDPLATFORM=linux/amd64

################################################################################
FROM --platform=${BUILDPLATFORM} golang:${GO_VERSION}-alpine${OS_VERESION} as base

# NOTE: add libusb-dev to run with LEDGER_ENABLED=true
RUN set -eux &&\
    apk update &&\
    apk add --no-cache \
    ca-certificates \
    linux-headers \
    build-base \
    cmake \
    bash \
    git

COPY ./bin/builder/ /usr/local/bin/

################################################################################
FROM base as builder

ARG APP_NAME="terra"
ARG BIN_NAME="${APP_NAME}d"
ARG BUILD_COMMAND="make install"
ARG BUILD_TAGS="muslc"
ARG COSMOS_BUILD_OPTIONS="nostrip"
ARG GIT_TAG="v2.4.1"
ARG GIT_REPO="terra-money/core"
#ARG LDFLAGS="-extldflags '-L/go/src/mimalloc/build -lmimalloc -Wl,-z,muldefs -static'"
ARG LDFLAGS='-extldflags "-Wl,-z,muldefs -static"'
ARG MIMALLOC_VERSION

ENV MIMALLOC_VERSION=${MIMALLOC_VERSION}
# install mimalloc if version is specified
RUN set -eux && \
    if [ -n "${MIMALLOC_VERSION}" ]; then install-mimalloc "${MIMALLOC_VERSION}"; fi

# download dependencies to cache as layer
WORKDIR ${GOPATH}/src/app

ENV GIT_TAG=${GIT_TAG} \
    GIT_REPO=${GIT_REPO}

RUN set -eux && \
    git clone -b ${GIT_TAG} https://github.com/${GIT_REPO}.git ./ && \
    go mod download -x

# download wasmvm if version is specified
RUN set -ux && \
    WASMVM_VERSION="$(go list -m github.com/CosmWasm/wasmvm | cut -d ' ' -f 2)" && \
    [ -n "${WASMVM_VERSION}" ] && install-wasmvm "${WASMVM_VERSION}"

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
# RUN set -x && \
#     file ${GOPATH}/bin/${BIN_NAME} && \
#     echo "Ensuring binary is statically linked ..." && \
#     (file ${GOPATH}/bin/${BIN_NAME} | grep "statically linked")

################################################################################
FROM --platform=${BUILDPLATFORM} alpine:${OS_VERESION} as prod

# build args passed down to env var

ARG APP_NAME="terra"
ARG BIN_NAME="${APP_NAME}d"
ARG USER_NAME="${APP_NAME}"

# copy binary
COPY --from=builder /go/bin/${BIN_NAME} /usr/local/bin/${BIN_NAME}

# install jq and create user
RUN set -eux && \   
    apk update && \
    apk add --no-cache bash curl jq && \
    addgroup -g 1000 ${USER_NAME} && \
    adduser -u 1000 -G ${USER_NAME} -D -h /home/${USER_NAME} ${USER_NAME} && \
    ln -s /usr/local/bin/${BIN_NAME} /usr/local/bin/chaind

# setup execution environment
USER ${USER_NAME}
WORKDIR /home/${USER_NAME}
CMD ["chaind", "start"]