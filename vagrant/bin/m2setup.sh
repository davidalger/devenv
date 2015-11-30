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

BRANCH=master
HOSTNAME=m2.dev
SAMPLEDATA=
GITHUB=

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
        -g|--github)
            GITHUB=1
            ;;
        --branch=*)
            BRANCH="${arg#*=}"
            if [[ ! "$BRANCH" =~ ^(master|develop)$ ]]; then
                >&2 echo "Error: Invalid value given --branch=$BRANCH (must be master or develop)"
                exit -1
            fi
            ;;
        --help)
            echo "Usage: $(basename $0) [-d|--sampledata] [-g|--github] [--branch=<name>] [--hostname=<example.dev>]"
            echo ""
            echo "  -d : --sampledata             triggers installation of sample data"
            echo "  -g : --github                 will install via github clone instead of from meta-packages"
            echo "       --hostname=<hostname>    domain of the site (defaults to m2.dev)"
            echo "       --branch=<branch>        branch to build the site from (defaults to master)"
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
    
    if [[ ! -d "$dest_path/.git" ]]; then
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
    tools_dir=$SITES_DIR/$HOSTNAME/var/.m2-data/dev/tools
    
    echo "==> Linking in sample data"
    mirror_repo https://github.com/magento/magento2-sample-data.git $SHARED_DIR/m2-data.repo
    clone_or_update $SHARED_DIR/m2-data.repo $SITES_DIR/$HOSTNAME/var/.m2-data $BRANCH
    php -f $tools_dir/build-sample-data.php -- --ce-source=$SITES_DIR/$HOSTNAME

    touch $SAMPLEDATA_INSTALLED
}

function install_from_github {

    # grab magento 2 codebase
    mirror_repo https://github.com/magento/magento2.git $SHARED_DIR/m2.repo
    clone_or_update $SHARED_DIR/m2.repo $SITES_DIR/$HOSTNAME $BRANCH

    # install all dependencies in prep for setup / upgrade
    echo "==> Installing composer dependencies"
    cd $SITES_DIR/$HOSTNAME
    composer install -q --no-interaction --prefer-dist

    if [[ $SAMPLEDATA ]]; then
        install_sample_data
    fi
}

function install_from_packages {

    if [[ ! -d "$SITES_DIR/$HOSTNAME/vendor" ]]; then
        echo "==> Installing magento meta-packages"
        composer create-project --repository-url=https://repo.magento.com/ \
            magento/project-community-edition $SITES_DIR/$HOSTNAME
    else
        composer update --prefer-dist
    fi
    
    chmod +x bin/magento

    if [[ $SAMPLEDATA ]]; then
        echo "==> Deploying sample data meta-packages"
        bin/magento sampledata:deploy
        composer update --prefer-dist
    fi
}

## begin execution

if [[ ! -d "$SITES_DIR/$HOSTNAME" ]]; then
    echo "==> Creating directory $SITES_DIR/$HOSTNAME"
    mkdir $SITES_DIR/$HOSTNAME
fi
cd $SITES_DIR/$HOSTNAME

if [[ $GITHUB ]]; then
    install_from_github
else
    install_from_packages
fi

# either install or upgrade database
code=
mysql -e "use $DB_NAME" 2> /dev/null || code="$?"
if [[ $code ]]; then
    echo "==> Creating $DB_NAME database"
    mysql -e "create database $DB_NAME"
    
    echo "==> Running bin/magento setup:install"
    bin/magento setup:install \
        --base-url=http://$HOSTNAME \
        --base-url-secure=https://$HOSTNAME \
        --use-secure=1 \
        --use-secure-admin=1 \
        --backend-frontname=backend \
        --admin-user=admin \
        --admin-firstname=Admin \
        --admin-lastname=Admin \
        --admin-email=user@example.com \
        --admin-password=A123456 \
        --db-host=dev-db \
        --db-user=root \
        --db-name=$DB_NAME
else
    echo "==> Database $DB_NAME already exists"
    echo "==> Running bin/magento setup:upgrade"
    bin/magento setup:upgrade -q
fi

echo "==> Flushing magento cache"
bin/magento cache:flush -q

echo "==> Flushing redis service"
redis-cli flushall > /dev/null

echo "==> Updating virtual hosts"
/server/vagrant/bin/vhosts.sh > /dev/null

cd "$wd"
