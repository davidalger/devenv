# download and install composer into vm
wd="$(pwd)"
set -e

download_url="http://files.magerun.net/n98-magerun-latest.phar"
magerun_path="/usr/local/bin/n98-magerun"
mr_path="/usr/local/bin/mr"

cd "$SHARED_DIR"

wget -qN "$download_url" || true
if [[ ! -f "$SHARED_DIR/n98-magerun-latest.phar" ]]; then
    >&2 echo "Error: failed to retrieve n98-magerun.phar and local cache is empty"
    exit -1;
fi
cp "$SHARED_DIR/n98-magerun-latest.phar" "$magerun_path"
chmod +x "$magerun_path"
ln -s "$magerun_path" "$mr_path"

cd "$wd"
