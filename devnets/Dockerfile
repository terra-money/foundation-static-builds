ARG IMAGE_NAME=terra
ARG IMAGE_TAG=2.4.1
ARG BUILDPLATFORM=linux/amd64

FROM --platform=${BUILDPLATFORM} terraformlabs/${IMAGE_NAME}:${IMAGE_TAG}

ARG NUM_VALIDATORS=1

COPY ./mnemonics.json ./
COPY ./init-chain ./bin/

ENV MNEMONIC_JSON="${WORKDIR}/mnemonics.json" \
    INIT_SCRIPTS="${WORKDIR}/bin/init-chain" \
    NUM_VALIDATORS=${NUM_VALIDATORS}
