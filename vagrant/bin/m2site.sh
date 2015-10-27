# install a magento 2 site
##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

set -e
wd="$(pwd)"

SHARED_DIR=/server/.shared
SITES_DIR=/server/sites

BRANCH=develop
HOSTNAME=m2.dev
SAMPLEDATA=

## argument parsing

for arg in "$@"; do
    case $arg in
        --hostname=*)
            HOSTNAME="${arg#*=}"
            if [[ ! "$HOSTNAME" =~ ^[a-z0-9]+\.[a-z]{2,5}$ ]]; then
                >&2 echo "Error: Invalid value given --hostname=$HOSTNAME"
                exit -1
            fi
            ;;
        -d|--sampledata)
            SAMPLEDATA=1
            ;;
        --branch=*)
            BRANCH="${arg#*=}"
            if [[ ! "$BRANCH" =~ ^(master|develop|merchant_beta)$ ]]; then
                >&2 echo "Error: Invalid value given --branch=$BRANCH (must be master, develop, or merchant_beta)"
                exit -1
            fi
            ;;
        --help)
            echo "Usage: $(basename $0) [-d] [--sampledata] [--hostname=example.dev]"
            echo ""
            echo "  -d : --sampledata             triggers installation of sample data"
            echo "       --hostname=<hostname>    domain of the site (defaults to m2.dev)"
            echo "       --branch=<branch>        branch to build the site from (defaults to develop)"
            echo ""
            exit -1
            ;;
        *)
            >&2 echo "Error: Unrecognized argument $arg"
            exit -1
            ;;
    esac
done

DB_NAME="$(printf "$HOSTNAME" | tr . _)"

# sampledata flag to prevent re-running the sampledata:install routine
SAMPLEDATA_INSTALLED=$SITES_DIR/$HOSTNAME/var/.sampledata
if [[ $SAMPLEDATA && -f $SAMPLEDATA_INSTALLED ]]; then
    SAMPLEDATA=
fi

## verify pre-requisites

if [[ -f /etc/.vagranthost ]]; then
    >&2 echo "Error: This script should be run from within the vagrant machine. Please vagrant ssh, then retry"
    exit 1
fi

php_version=$(php -r 'echo phpversion();' | cut -d . -f2)
if [[ $php_version < 5 ]]; then
    >&2 echo "Error: Magento 2 requires PHP 5.5 or newer"
    exit
fi

# use a bare clone to keep up-to-date local mirror of master
function mirror_repo {
    wd="$(pwd)"
    
    repo_url="$1"
    mirror_path="$2"
    
    if [[ ! -d "$mirror_path" ]]; then
        echo "==> Mirroring $repo_url -> $mirror_path"
        git clone --bare -q "$repo_url" "$mirror_path"
        cd "$mirror_path"
        git remote add origin "$repo_url"
        git config remote.origin.fetch 'refs/heads/*:refs/heads/*'
        git fetch -q
    else
        echo "==> Updating mirror $mirror_path"
        cd "$mirror_path"
        git config remote.origin.fetch 'refs/heads/*:refs/heads/*'  # in case it's not previously been set
        git fetch -q || true
    fi
    
    cd "$wd"
}

# install or update codebase from local mirror
function clone_or_update {
    wd="$(pwd)"
    
    repo_url="$1"
    dest_path="$2"
    branch_name="$3"
    
    if [[ ! -d "$dest_path" ]]; then
        echo "==> Cloning $repo_url -> $dest_path"

        mkdir -p "$dest_path"
        git clone -q "$repo_url" "$dest_path"

        cd "$dest_path"
        git checkout -q "$branch_name"
    else
        echo "Updating $dest_path from mirror"
        cd "$dest_path"
        git checkout -q "$branch_name"
        git pull -q
    fi
    
    cd "$wd"
}

# runs the install routine for sample data if enabled
function install_sample_data {
    tools_dir=$SITES_DIR/$HOSTNAME/var/tmp/m2-data/dev/tools
    
    # grab sample data assets
    mirror_repo https://github.com/magento/magento2-sample-data.git $SHARED_DIR/m2-data.repo
    clone_or_update $SHARED_DIR/m2-data.repo $SITES_DIR/$HOSTNAME/var/tmp/m2-data $BRANCH
    php -f $tools_dir/build-sample-data.php -- --ce-source=$SITES_DIR/$HOSTNAME

    echo "==> Installing sample data"
    bin/magento setup:upgrade -q
    bin/magento sampledata:install admin
    touch $SAMPLEDATA_INSTALLED
    bin/magento module:disable Magento_SampleData
    php -f $tools_dir/build-sample-data.php -- --ce-source=$SITES_DIR/$HOSTNAME --command unlink

    if [[ ! -L $SITES_DIR/$HOSTNAME/pub/pub/media/styles.css ]]; then
        echo "==> Fixing sample data stylesheet location bug... (see issue #2)"
        mkdir -p $SITES_DIR/$HOSTNAME/pub/pub/media
        ln -s ../../media/styles.css $SITES_DIR/$HOSTNAME/pub/pub/media/styles.css
    fi
}

## begin execution

# grab magento 2 codebase
mirror_repo https://github.com/magento/magento2.git $SHARED_DIR/m2.repo
clone_or_update $SHARED_DIR/m2.repo $SITES_DIR/$HOSTNAME $BRANCH

# install all dependencies in prep for setup / upgrade
echo "==> Installing composer dependencies"
cd $SITES_DIR/$HOSTNAME
composer install -q --no-interaction --prefer-dist

# either install or upgrade database
code=
mysql -e "use $DB_NAME" 2> /dev/null || code="$?"
if [[ $code ]]; then
    echo "==> Creating $DB_NAME database"
    mysql -e "create database $DB_NAME"
    
    echo "==> Running bin/magento setup:install"
    bin/magento setup:install -q \
        --base-url=http://$HOSTNAME \
        --backend-frontname=backend \
        --admin-user=admin \
        --admin-firstname=Admin \
        --admin-lastname=Admin \
        --admin-email=user@example.com \
        --admin-password=A123456 \
        --db-host=dev-db \
        --db-user=root \
        --db-name=$DB_NAME
    
    if [[ $SAMPLEDATA ]]; then
        install_sample_data
    fi
else
    echo "==> Database $DB_NAME already exists"
    echo "==> Running bin/magento setup:upgrade"
    bin/magento setup:upgrade -q
    
    if [[ $SAMPLEDATA ]]; then
        install_sample_data
    fi
fi

echo "==> Removing var directories"
rm -rf var/{cache,page_cache,session,log,generation,composer_home,view_preprocessed}/*

echo "==> Flushing redis service"
redis-cli flushall > /dev/null

echo "==> Updating virtual hosts"
/server/vagrant/bin/vhosts.sh > /dev/null

cd "$wd"
