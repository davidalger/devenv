# install a sandbox m2.dev site
set -e
wd=$(pwd)

SHARED_DIR=/server/.shared
SITES_DIR=/server/sites

if [[ -f /etc/.vagranthost ]]; then
    >&2 echo "Error: This script should be run from within the vagrant machine. Please vagrant ssh, then retry"
    exit 1
fi

php_version=$(php -r 'echo phpversion();' | cut -d . -f2)
if [[ $php_version < 5 ]]; then
    echo "Error: Magento 2 requires PHP 5.5 or newer"
    exit
fi

var_dirs=cache,page_cache,session,log,generation,composer_home,view_preprocessed

# use a bare clone to keep up-to-date local mirror of master
if [[ ! -d "$SHARED_DIR/m2.repo" ]]; then
    echo "Cloning remote repository to local mirror. This could take a while..."
    git clone --bare -q "https://github.com/magento/magento2.git" "$SHARED_DIR/m2.repo"
    cd "$SHARED_DIR/m2.repo"
    git remote add origin "https://github.com/magento/magento2.git"
    git fetch -q
else
    echo "Updating local magento2 repository mirror"
    cd "$SHARED_DIR/m2.repo"
    git fetch -q || true
fi

# install or update codebase from local mirror
if [[ ! -d "$SITES_DIR/m2.dev" ]]; then
    echo "Setting up site from scratch. This could take a while..."

    mkdir -p "$SITES_DIR/m2.dev"
    git clone -q "$SHARED_DIR/m2.repo" "$SITES_DIR/m2.dev"

    cd "$SITES_DIR/m2.dev"
    bash -c "ln -s /server/_var/m2.dev/{$var_dirs} var/"
else
    echo "Updating site from mirror"
    cd "$SITES_DIR/m2.dev"
    git pull -q
fi

# make sure linked var_dirs targets exist and owned properly
bash -c "sudo mkdir -p /server/_var/m2.dev/{$var_dirs}"
sudo chown -R vagrant:vagrant "/server/_var/"
sudo chmod -R 777 "/server/_var/"
bash -c "sudo rm -rf var/{$var_dirs}/*" # flush all var_dirs just in case they already existed

# install all dependencies in prep for setup / upgrade
echo "Installing composer dependencies"
composer install -q --no-interaction --prefer-dist

# either install or upgrade database
code=
mysql -e 'use m2_dev' 2> /dev/null || code="$?"
if [[ $code ]]; then
    echo "Initializing database via setup:install"
    mysql -e 'create database m2_dev'
    
    bin/magento setup:install -q \
        --backend-frontname=backend \
        --admin-user=admin \
        --admin-firstname=Admin \
        --admin-lastname=Admin \
        --admin-email=user@example.com \
        --admin-password=A123456 \
        --db-host=dev-db \
        --db-user=root \
        --db-name="m2_dev"
else
    echo "Running setup:upgrade"
    bin/magento setup:upgrade -q
fi

echo "Flushing all file caches"
bash -c "sudo rm -rf var/{$var_dirs}/*"

echo "Running vhosts.sh and reloading apache"
/server/vagrant/bin/vhosts.sh > /dev/null

cd "$wd"
