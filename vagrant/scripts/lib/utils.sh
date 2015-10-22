#!/usr/bin/env bash
##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

set -e

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
