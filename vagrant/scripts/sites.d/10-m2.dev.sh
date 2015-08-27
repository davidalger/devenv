# install a sandbox m2.dev site
set -e
wd=$(pwd)

if [[ ! -d "$CACHE_DIR/m2.repo" ]]; then
    git clone --mirror -q "https://github.com/magento/magento2.git" "$CACHE_DIR/m2.repo"
else
    cd "$CACHE_DIR/m2.repo"
    git fetch -q || true
fi

if [[ ! -d "$SITES_DIR/m2.dev" ]]; then
    echo "Setting up site from scratch. This could take a while..."
    
    mkdir -p "$SITES_DIR/m2.dev"
    git clone -q "$CACHE_DIR/m2.repo" "$SITES_DIR/m2.dev"

    cd "$SITES_DIR/m2.dev"
    composer install -q --prefer-dist
    mysql -e 'create database m2_dev'

    bin/magento setup:install -q \
        --admin-user=admin \
        --admin-firstname=Admin \
        --admin-lastname=Admin \
        --admin-email=user@example.com \
        --admin-password=A123456 \
        --db-host=dev-db \
        --db-user=root \
        --db-name="m2_dev"
    
    >&2 echo "Note: please add a record to your /etc/hosts file for m2.dev and re-run the vhost generator"
else
    cd "$SITES_DIR/m2.dev"
    git pull -q

    cd "$SITES_DIR/m2.dev"
    composer install -q
    bin/magento setup:upgrade -q
fi

cd "$wd"
