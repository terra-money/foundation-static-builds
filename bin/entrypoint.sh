#!/usr/bin/env bash
set -Eeuo pipefail

BIN_NAME=${BIN_NAME:-"chaind"}

# if first arg looks like a flag, assume we want to run the binary
if [ "${1:0:1}" = '-' ]; then
    set -- "${BIN_NAME}" "$@"
fi

# run init scripts if found
if [ -d "/etc/init.d" ]; then
    for file in /etc/init.d/*; do
        if [ -x "${file}" ]; then
            echo "Running ${file}"
            ${file}
        fi
    done
fi

# run the command
exec "$@"