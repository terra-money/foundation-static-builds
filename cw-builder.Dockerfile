ARG IMG_TAG="latest"
ARG WASMVM_VERSION="1.3.0"
ARG BUILDPLATFORM="linux/amd64"
FROM --platform=${BUILDPLATFORM}} ghcr.io/terra-project/cosmos-docker-builds/alpine-base:${IMG_TAG}

ARG BUILDPLATFORM

# Cosmwasm - Download correct libwasmvm version
RUN set -eux &&\
    WASMVM_DOWNLOADS="https://github.com/CosmWasm/wasmvm/releases/download/${WASMVM_VERSION}"; \
    wget ${WASMVM_DOWNLOADS}/checksums.txt -O /tmp/checksums.txt; \
    if [ ${BUILDPLATFORM} = "linux/amd64" ]; then \
        wget ${WASMVM_DOWNLOADS}/libwasmvm_muslc.x86_64.a -O /lib/libwasmvm_muslc.a; \
        wget ${WASMVM_DOWNLOADS}/libwasmvm.x86_64.so -O /lib/libwasmvm.so; \
    elif [ ${BUILDPLATFORM} = "linux/arm64" ]; then \
        wget ${WASMVM_DOWNLOADS}/libwasmvm_muslc.aarch64.a -O /lib/libwasmvm_muslc.a; \
        wget ${WASMVM_DOWNLOADS}/libwasmvm.aarch64.so -O /lib/libwasmvm.so; \
    else \
        echo "Unsupported Build Platfrom ${BUILDPLATFORM}"; \
        exit 1; \
    fi; \
    CHECKSUM=`sha256sum /lib/libwasmvm_muslc.a | cut -d" " -f1`; \
    grep ${CHECKSUM} /tmp/checksums.txt; \
    CHECKSUM=`sha256sum /lib/libwasmvm.so | cut -d" " -f1`; \
    grep ${CHECKSUM} /tmp/checksums.txt; \
    rm /tmp/checksums.txt 