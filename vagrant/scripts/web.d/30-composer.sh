# download and install composer into vm
wd="$(pwd)"
set -e

composer_url="https://getcomposer.org/composer.phar"
composer_home="$CACHE_DIR/composer"
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
