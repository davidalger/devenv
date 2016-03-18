#!/usr/bin/env bash
##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

########################################
# Run specified role scripts on a node
# 
# Options:
# 
# Set the VAGRANT_ALLOWABLE_ROLES environment variable to filter roles during provisioning. Example usage:
# `export VAGRANT_ALLOWABLE_ROLES="node sites"` will prevent any role other than 'node' or 'sites' from running.
#

set -e

cd $VAGRANT_DIR
PATH="/usr/local/bin:$PATH"
source ./scripts/lib/utils.sh
source ./scripts/lib/vars.sh

echo "==> BEGIN bootstrap.sh at $(datetime) UTC" >> $BOOTSTRAP_LOG

# filter roles by those specified in env var
roles=""
if [[ "$ALLOWABLE_ROLES" ]]; then
    for role in $ALLOWABLE_ROLES; do
        if [[ " $@ " =~ .*" $role ".* ]]; then
            roles="$roles $role"
        fi
    done
else
    roles="$@"
fi

# allow caller to specify verbose mode where stdout is passed along vs only logged
if [[ "$VERBOSE" == 'true' ]]; then
    STDOUT='/dev/stdout'
else
    STDOUT='/dev/null'
fi

# execute role specific scripts
for role in $roles; do
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
