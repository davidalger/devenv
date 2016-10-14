#!/usr/bin/env bash
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

trap '>&2 echo Error: Command \`$BASH_COMMAND\` on line $LINENO failed with exit code $?' ERR

# init non-user configurable inputs allowing external override via exports
test -z $SHARED_DIR && SHARED_DIR=/server/.shared
test -z $SITES_DIR && SITES_DIR=/server/sites
test -z $INSTALL_DIR && INSTALL_DIR=        # default init'd post argument parsing
test -z $DB_HOST && DB_HOST=dev-db
test -z $DB_USER && DB_USER=root
test -z $DB_NAME && DB_NAME=            # default init'd post argument parsing

# init user configurable inputs
BRANCH=develop
HOSTNAME=
URLPATH=
BACKEND_FRONTNAME=backend
ADMIN_USER=admin
ADMIN_EMAIL=demouser@example.com
ADMIN_FIRST=Demo
ADMIN_LAST=User
test -z $ADMIN_PASS && ADMIN_PASS="$(openssl rand -base64 24)"

# user set flags
SAMPLEDATA=
ENTERPRISE=
NO_COMPILE=
GITHUB=
VERBOSE=

## argument parsing

for arg in "$@"; do
    case $arg in
        -v|--verbose)
            VERBOSE=1
            ;;
        -d|--sampledata)
            SAMPLEDATA=1
            ;;
        -e|--enterprise)
            ENTERPRISE=1
            ;;
        -g|--github)
            GITHUB=1
            ;;
        -C|--no-compile)
            NO_COMPILE=1
            ;;
        --hostname=*)
            HOSTNAME="${arg#*=}"
            if [[ ! "$HOSTNAME" =~ ^[a-z0-9\.\-]+\.[a-z]{2,5}$ ]]; then
                >&2 echo "Error: Invalid value given --hostname=$HOSTNAME"
                exit -1
            fi
            ;;
        --urlpath=*)
            URLPATH="${arg#*=}"
            if [[ ! "$URLPATH" =~ ^[a-z0-9][a-z0-9/]*[a-z0-9]+$ ]]; then
                >&2 echo "Error: Invalid value given --urlpath=$URLPATH"
                exit -1
            fi
            ;;
        --branch=*)
            BRANCH="${arg#*=}"
            if [[ ! "$BRANCH" =~ ^(2\.0|develop)$ ]]; then
                >&2 echo "Error: Invalid value given --branch=$BRANCH (must be '2.0' or develop)"
                exit -1
            fi
            ;;
        --proj-version=*)
            PROJ_VERSION="${arg#*=}"
            if [[ ! "$PROJ_VERSION" =~ ^.+$ ]]; then
                >&2 echo "Error: Invalid value given --proj-version=$PROJ_VERSION"
                exit -1
            fi
            ;;
        --backend-frontname=*)
            BACKEND_FRONTNAME="${arg#*=}"
            if [[ ! "$BACKEND_FRONTNAME" =~ ^([a-zA-Z0-9]+)$ ]]; then
                >&2 echo "Error: Invalid value given --backend-frontname=$BACKEND_FRONTNAME " \
                    "(only alphanumerical values allowed)"
                exit -1
            fi
            ;;
        --admin-user=*)
            ADMIN_USER="${arg#*=}"
            if [[ ! "$ADMIN_USER" =~ ^([a-zA-Z0-9]+)$ ]]; then
                >&2 echo "Error: Invalid value given --admin-user=$ADMIN_USER (only alphanumerical values allowed)"
                exit -1
            fi
            ;;
        --admin-first=*)
            ADMIN_FIRST="${arg#*=}"
            if [[ ! "$ADMIN_FIRST" =~ ^([a-zA-Z0-9]+)$ ]]; then
                >&2 echo "Error: Invalid value given --admin-first=$ADMIN_FIRST (only alphanumerical values allowed)"
                exit -1
            fi
            ;;
        --admin-last=*)
            ADMIN_LAST="${arg#*=}"
            if [[ ! "$ADMIN_LAST" =~ ^([a-zA-Z0-9]+)$ ]]; then
                >&2 echo "Error: Invalid value given --admin-last=$ADMIN_LAST (only alphanumerical values allowed)"
                exit -1
            fi
            ;;
        --admin-email=*)
            ADMIN_EMAIL="${arg#*=}"
            if [[ ! "$ADMIN_EMAIL" =~ ^(.+@.+\..+)$ ]]; then
                >&2 echo "Error: Invalid value given --admin-email=$ADMIN_EMAIL (must be valid email address)"
                exit -1
            fi
            ;;
        --help)
            echo "Usage: $(basename $0) [-v|--verbose] [-d|--sampledata] [-e|--enterprise] [-g|--github] "
            echo "     --hostname=<example.dev> [--urlpath=<name>] [--branch=<name>] [--admin-user=<admin>] "
            echo "     [--admin-email=<email>] [--admin-first=<name>] [--admin-last=<name>]"
            echo ""
            echo "  -v : --verbose                          disables the -q flags on sub-commands for verbose output"
            echo "  -d : --sampledata                       triggers installation of sample data"
            echo "  -e : --enterprise                       uses enterprise meta-packages vs community"
            echo "  -g : --github                           will install via github clone instead of from meta-packages"
            echo "  -C : --no-compile                       skips DI compilation process and static asset generation"
            echo "       --proj-version=<proj-version>      composer package version to use during installation"
            echo "       --hostname=<hostname>              domain of the site (required input)"
            echo "       --urlpath=<urlpath>                path component of base url and install sub-directyory"
            echo "       --branch=<branch>                  branch to build the site from (defaults to develop)"
            echo "       --backend-frontname=<frontname>    alphanumerical admin username (defaults to backend)"
            echo "       --admin-user=<admin>               alphanumerical admin username (defaults to admin)"
            echo "       --admin-email=<email>              admin account email address"
            echo "       --admin-first=<name>               admin user first name"
            echo "       --admin-name=<name>                admin user last name"
            echo ""
            exit -1
            ;;
        *)
            >&2 echo "Error: Unrecognized argument $arg"
            exit -1
            ;;
    esac
done

if [[ -z $DB_NAME ]]; then
    DB_NAME="$(printf "$HOSTNAME" | tr . _)"
fi

if [[ -z $INSTALL_DIR ]]; then
    INSTALL_DIR=$SITES_DIR/$HOSTNAME
    if [[ -z $URLPATH ]]; then
        INSTALL_DIR=$INSTALL_DIR/$URLPATH
    fi
fi

# simply needs to be the hostname + urlpath (if given), the protocol is added later
BASE_URL=$HOSTNAME
if [[ ! -z $URLPATH ]]; then
    BASE_URL=$BASE_URL/$URLPATH
fi

# sampledata flag to prevent re-running the sampledata:install routine
SAMPLEDATA_INSTALLED=$INSTALL_DIR/var/.sampledata
if [[ $SAMPLEDATA && -f $SAMPLEDATA_INSTALLED ]]; then
    SAMPLEDATA=
fi

# configure verbosity flags; currently we support queit and normal verbosity of sub-commands via a single flag
NOISE_LEVEL=" "
if [[ ! $VERBOSE ]]; then
    NOISE_LEVEL=" -q "
fi

## verify pre-requisites

if [[ ! "$HOSTNAME" ]]; then
    >&2 echo "Error: Required input --hostname missing. Please use --help for proper usage"
    exit -1
fi

if [[ ! "$ADMIN_EMAIL" ]] || [[ ! "$ADMIN_FIRST" ]] || [[ ! "$ADMIN_LAST" ]]; then
    >&2 echo "Error: Required admin account information missing. Please use --help for proper usage"
    exit -1
fi

if [[ -f /etc/.vagranthost ]]; then
    >&2 echo "Error: This script should be run from within the vagrant machine. Please vagrant ssh, then retry"
    exit 1
fi

php_vercheck=$(php -r 'echo version_compare(PHP_VERSION, "5.6.0", ">=") ? 1 : "";')
if [[ -z $php_vercheck ]]; then
    >&2 echo "Error: Magento 2 requires PHP 5.6 or newer"
    exit
fi

# use a bare clone to keep up-to-date local mirror of master
function mirror_repo {
    wd="$(pwd)"
    
    repo_url="$1"
    mirror_path="$2"
    
    if [[ ! -d "$mirror_path" ]]; then
        echo "==> Mirroring $repo_url -> $mirror_path"
        git clone --bare $NOISE_LEVEL "$repo_url" "$mirror_path"
        cd "$mirror_path"
        git remote add origin "$repo_url"
        git config remote.origin.fetch 'refs/heads/*:refs/heads/*'
        git fetch $NOISE_LEVEL
    else
        echo "==> Updating mirror $mirror_path"
        cd "$mirror_path"
        git config remote.origin.fetch 'refs/heads/*:refs/heads/*'  # in case it's not previously been set
        git fetch|| true
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
        git clone $NOISE_LEVEL "$repo_url" "$dest_path"

        cd "$dest_path"
        git checkout $NOISE_LEVEL "$branch_name"
    else
        echo "Updating $dest_path from mirror"
        cd "$dest_path"
        git checkout $NOISE_LEVEL "$branch_name"
        git pull $NOISE_LEVEL
    fi
    
    cd "$wd"
}

# runs the install routine for sample data if enabled
function install_sample_data {
    tools_dir=$INSTALL_DIR/var/.m2-data/dev/tools
    
    echo "==> Linking in sample data"
    mirror_repo https://github.com/magento/magento2-sample-data.git $SHARED_DIR/m2-data.repo
    clone_or_update $SHARED_DIR/m2-data.repo $INSTALL_DIR/var/.m2-data $BRANCH
    php -f $tools_dir/build-sample-data.php -- --ce-source=$INSTALL_DIR

    touch $SAMPLEDATA_INSTALLED
}

function install_from_github {

    # grab magento 2 codebase
    mirror_repo https://github.com/magento/magento2.git $SHARED_DIR/m2.repo
    clone_or_update $SHARED_DIR/m2.repo $INSTALL_DIR $BRANCH

    # install all dependencies in prep for setup / upgrade
    echo "==> Installing composer dependencies"
    cd $INSTALL_DIR
    composer install $NOISE_LEVEL --no-interaction --prefer-dist

    if [[ $SAMPLEDATA ]]; then
        install_sample_data
    fi
}

function install_from_packages {

    if [[ ! -d "$INSTALL_DIR/vendor" ]]; then
        echo "==> Installing magento meta-packages"

        package_name="magento/project-community-edition"
        if [[ $ENTERPRISE ]]; then
            package_name="magento/project-enterprise-edition"
        fi
        
        composer create-project $NOISE_LEVEL --no-interaction --prefer-dist \
            --repository-url=https://repo.magento.com/ $package_name $INSTALL_DIR "$PROJ_VERSION"
    else
        echo "==> Updating magento meta-packages"
        composer update $NOISE_LEVEL --no-interaction --prefer-dist
    fi
    
    chmod +x bin/magento

    if [[ $SAMPLEDATA ]]; then
        echo "==> Deploying sample data meta-packages"
        COMPOSER_NO_INTERACTION=1 bin/magento sampledata:deploy $NOISE_LEVEL
        composer update $NOISE_LEVEL --no-interaction --prefer-dist
    fi
}

function print_install_info {
    URL_FRONT="http://$BASE_URL"
    URL_ADMIN="https://$BASE_URL/$BACKEND_FRONTNAME/admin"

    FILL=$(printf "%0.s-" {1..128})
    C1_LEN=8
    let "C2_LEN=${#URL_ADMIN}>${#ADMIN_PASS}?${#URL_ADMIN}:${#ADMIN_PASS}"
    
    # note: in CentOS bash .* isn't supported (is on Darwin), but *.* is more cross-platform
    printf "+ %*.*s + %*.*s + \n" 0 $C1_LEN $FILL 0 $C2_LEN $FILL
    printf "+ %-*s + %-*s + \n" $C1_LEN FrontURL $C2_LEN "$URL_FRONT"
    printf "+ %*.*s + %*.*s + \n" 0 $C1_LEN $FILL 0 $C2_LEN $FILL
    printf "+ %-*s + %-*s + \n" $C1_LEN AdminURL $C2_LEN "$URL_ADMIN"
    printf "+ %*.*s + %*.*s + \n" 0 $C1_LEN $FILL 0 $C2_LEN $FILL
    printf "+ %-*s + %-*s + \n" $C1_LEN Username $C2_LEN "$ADMIN_USER"
    printf "+ %*.*s + %*.*s + \n" 0 $C1_LEN $FILL 0 $C2_LEN $FILL
    printf "+ %-*s + %-*s + \n" $C1_LEN Password $C2_LEN "$ADMIN_PASS"
    printf "+ %*.*s + %*.*s + \n" 0 $C1_LEN $FILL 0 $C2_LEN $FILL
}

## begin execution

if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "==> Creating directory $INSTALL_DIR"
    mkdir -p $INSTALL_DIR
fi
cd $INSTALL_DIR

if [[ $GITHUB ]]; then
    install_from_github
else
    install_from_packages
fi

# link session dir so install won't choke trying to lock a session file on an nfs mount
ln -s /var/lib/php/session var/session

# either install or upgrade database
print_info_flag=
code=
mysql -e "use $DB_NAME" 2> /dev/null || code="$?"
if [[ $code ]]; then
    echo "==> Creating $DB_NAME database"
    mysql -e "create database $DB_NAME"
    
    echo "==> Running bin/magento setup:install"
    bin/magento $NOISE_LEVEL setup:install           \
        --base-url="http://$BASE_URL"                \
        --base-url-secure="https://$BASE_URL"        \
        --backend-frontname="$BACKEND_FRONTNAME"     \
        --use-secure=1                               \
        --use-secure-admin=1                         \
        --use-rewrites=1                             \
        --admin-user="$ADMIN_USER"                   \
        --admin-firstname="$ADMIN_FIRST"             \
        --admin-lastname="$ADMIN_LAST"               \
        --admin-email="$ADMIN_EMAIL"                 \
        --admin-password="$ADMIN_PASS"               \
        --db-host="$DB_HOST"                         \
        --db-user="$DB_USER"                         \
        --db-name="$DB_NAME"                         \
        --magento-init-params 'MAGE_MODE=production' \
    ;
    
    print_info_flag=1
else
    echo "==> Database $DB_NAME already exists"
    echo "==> Running bin/magento setup:upgrade"
    bin/magento setup:upgrade $NOISE_LEVEL
fi

if [[ ! $NO_COMPILE ]]; then
    echo "==> Compiling DI and generating static content"
    rm -rf var/di/ var/generation/
    # Magento 2.0.x required usage of multi-tenant compiler (see here for details: http://bit.ly/21eMPtt).
    # Magento 2.1 dropped support for the multi-tenant compiler, so we must use the normal compiler.
    if [ `bin/magento setup:di:compile-multi-tenant --help &> /dev/null; echo $?` -eq 0 ]; then
        bin/magento setup:di:compile-multi-tenant $NOISE_LEVEL
    else
        bin/magento setup:di:compile $NOISE_LEVEL
    fi
    bin/magento setup:static-content:deploy $NOISE_LEVEL
    bin/magento cache:flush $NOISE_LEVEL
fi

echo "==> Reindexing and flushing magento cache"
bin/magento indexer:reindex $NOISE_LEVEL
bin/magento cache:flush $NOISE_LEVEL

echo "==> Flushing redis service"
redis-cli flushall > /dev/null

if [[ $print_info_flag ]]; then
    echo "==> New site information:"
    print_install_info
    echo ""
fi

echo "Please update any necessary virtual hosts and/or other server configuration!"

cd "$wd"
