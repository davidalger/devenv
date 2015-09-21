#!/usr/bin/env bash

function datetime {
    date -u '+%F %H:%m:%S'
}

function log {
    echo "==> [$(datetime)] $@" >> $BOOTSTRAP_LOG
}

function log_tee {
    log "$@"
    echo "$@"
}

function log_err {
    >&2 log_tee "$@"
}
