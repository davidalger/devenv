#!/usr/bin/env bash
# 
# Runs each of the specified role-based scripts on a node
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

# execute role specific scripts
for role in $roles; do
    if [[ -d "./scripts/$role.d/" ]]; then
        log_tee "Configuring for $role role"
        for script in $(ls -1 ./scripts/$role.d/*.sh); do
            log "Running: $role: $(basename $script)"
            
            ./$script   \
                >> $BOOTSTRAP_LOG   \
                2> >(tee -a $BOOTSTRAP_LOG | grep -v -f $VAGRANT_DIR/etc/filters/bootstrap >&2) \
                || code="$?"
            
            if [[ $code ]]; then
                log_err "Error: $script failed with return code $code"
                code=""
            fi
        done
    else
        log_tee "Skipping invalid role: $role"
    fi
done

echo "==> END bootstrap.sh at $(datetime) UTC" >> $BOOTSTRAP_LOG
