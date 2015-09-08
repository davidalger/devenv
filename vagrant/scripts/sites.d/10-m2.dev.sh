# install a sandbox m2.dev site
set -e
wd=$(pwd)

var_dirs=cache,page_cache,session,log,generation,composer_home,view_preprocessed

# use a bare clone to keep up-to-date local mirror of master
if [[ ! -d "$CACHE_DIR/m2.repo" ]]; then
    echo "Cloning remote repository to local mirror. This could take a while..."
    git clone --bare -q "https://github.com/magento/magento2.git" "$CACHE_DIR/m2.repo"
    cd "$CACHE_DIR/m2.repo"
    git remote add origin "https://github.com/magento/magento2.git"
    git fetch -q
else
    cd "$CACHE_DIR/m2.repo"
    git fetch -q || true
fi

# install or update codebase from local mirror
if [[ ! -d "$SITES_DIR/m2.dev" ]]; then
    echo "Setting up site from scratch. This could take a while..."
    >&2 echo "Note: please add a record to your /etc/hosts file for m2.dev and re-run the vhost generator"
    
    mkdir -p "$SITES_DIR/m2.dev"
    git clone -q "$CACHE_DIR/m2.repo" "$SITES_DIR/m2.dev"

    cd "$SITES_DIR/m2.dev"
    bash -c "ln -s /server/_var/m2.dev/{$var_dirs} var/"
else
    cd "$SITES_DIR/m2.dev"
    git pull -q
fi

# make sure linked var_dirs targets exist and owned properly
bash -c "mkdir -p /server/_var/m2.dev/{$var_dirs}"
chown -R vagrant:vagrant "/server/_var/"
chmod -R 777 "/server/_var/"

# flush all var_dirs
bash -c "rm -rf var/{$var_dirs}/*"

# install all dependencies in prep for setup / upgrade
composer install -q --no-interaction --prefer-dist

# either install or upgrade database
code=
mysql -e 'use m2_dev' 2> /dev/null || code="$?"
if [[ $code ]]; then
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
    bin/magento setup:upgrade -q
fi

cd "$wd"
