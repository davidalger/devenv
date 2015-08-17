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
cd /vagrant

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
        echo "Configuring for $role role"
        
        for script in $(ls -1 ./scripts/$role.d/*.sh); do
            echo "Running: $role: $(basename $script)"
            ./$script
        done
    else
        echo "Skipping invalid role: $role"
    fi
done
