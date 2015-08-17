#!/usr/bin/env bash

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
    echo "Configuring $role role"
    
    for script in $(ls -1 scripts/$role.d/*.sh); do
        echo "Running: $role: $(basename $script)"
        ./$script
    done
done
