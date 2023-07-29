#!/usr/bin/env bash
set -Eeuo pipefail

BIN_NAME=${BIN_NAME:-"chaind"}
INIT_SCRIPTS=${INIT_SCRIPTS:-""}

# if first arg looks like a flag, assume we want to run the binary
if [ "${1:0:1}" = '-' ]; then
    set -- "${BIN_NAME}" "$@"
fi

# run init scripts if found
for script in ${INIT_SCRIPTS}; do
    if [ -x "${script}" ]; then
        echo "Running ${script}"
        ${script}
    fi
done

# run the command
exec "$@"