#!/usr/bin/env bash

source sh/lib/logger.sh || exit 1

log::info "Updating..."
dnf update -y
if [[ $? -ne 0 ]]; then
    log::error "Command 'dnf' returned non-zero code. Failed to update."
    exit 1
fi

while read -r line; do
    dnf install "$line"
    if [[ $? -ne 0 ]]; then
        log::error "Command 'dnf' returned non-zero code. Failed to install '${line}'."
        exit 1
    fi
done < "packages.txt"
