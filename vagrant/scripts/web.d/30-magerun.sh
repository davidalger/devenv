#!/usr/bin/env bash
##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

########################################
# download and install composer into vm

wd="$(pwd)"
set -e

function install_mr {
    download_url="$1"
    install_path="$2"
    shortcut_tla="$3"

    file_name="$(basename $download_url)"
    cd "$SHARED_DIR"

    wget -qN "$download_url" || true
    if [[ ! -f "$SHARED_DIR/$file_name" ]]; then
        >&2 echo "Error: failed to retrieve $file_name and local cache is empty"
    fi

    cp "$SHARED_DIR/$file_name" "$install_path"
    chmod +x "$install_path"

    ln -s "$install_path" "$shortcut_tla"
}

install_mr http://files.magerun.net/n98-magerun-latest.phar /usr/local/bin/n98-magerun /usr/local/bin/mr1
install_mr http://files.magerun.net/n98-magerun2-latest.phar /usr/local/bin/n98-magerun2 /usr/local/bin/mr2

ln -s /usr/local/bin/mr1 /usr/local/bin/mr

cd "$wd"
