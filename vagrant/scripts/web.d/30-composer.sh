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

composer_url="https://getcomposer.org/composer.phar"
composer_home="$SHARED_DIR/composer"
composer_path="/usr/local/bin/composer"

mkdir -p "$composer_home"
cd "$composer_home"

wget -qN "$composer_url" || true
if [[ ! -f "$composer_home/composer.phar" ]]; then
    >&2 echo "Error: failed to retrieve composer.phar and local cache is empty"
    exit -1;
fi
cp "$composer_home/composer.phar" "$composer_path"
chmod +x "$composer_path"

cd "$wd"
