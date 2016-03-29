#!/usr/bin/env bash
##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

set -e
cd $VAGRANT_DIR

source ./scripts/lib/utils.sh
source ./scripts/lib/vars.sh

echo "==> BEGIN bootstrap.sh at $(datetime) UTC" >> $BOOTSTRAP_LOG

[[ "$VERBOSE" == 'true' ]] && STDOUT='/dev/stdout' || STDOUT='/dev/null'

for role in "$@"; do
    if [[ -f "./scripts/$role.sh" ]]; then
        log_tee "Configuring for $role role"
        
        ./scripts/$role.sh   \
             > >(tee -a $BOOTSTRAP_LOG >(stdbuf -oL grep -E '^:: ') > $STDOUT) \
            2> >(tee -a $BOOTSTRAP_LOG | stdbuf -oL grep -vE -f $VAGRANT_DIR/etc/filters/bootstrap >&2) \
            || code="$?"
        
        if [[ $code ]]; then
            log_err "Error: $role.sh failed with return code $code"
            code=""
        fi
    else
        log_tee "Skipping invalid role: $role"
    fi
done

echo "==> END bootstrap.sh at $(datetime) UTC" >> $BOOTSTRAP_LOG
