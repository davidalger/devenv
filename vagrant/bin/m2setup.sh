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
BACKEND_FRONTNAME=backend
ADMIN_USER=admin
ADMIN_EMAIL=demouser@example.com
ADMIN_FIRST=Demo
ADMIN_LAST=User
ADMIN_PASS="$(openssl rand -base64 24)"
DB_HOST=dev-db
DB_USER=root
DB_NAME=            # default init'd post argument parsing
SAMPLEDATA=
ENTERPRISE=
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
        -e|--enterprise)
            ENTERPRISE=1
            ;;
        -g|--github)
            GITHUB=1
            ;;
        --branch=*)
            BRANCH="${arg#*=}"
            if [[ ! "$BRANCH" =~ ^(2\.0|develop)$ ]]; then
                >&2 echo "Error: Invalid value given --branch=$BRANCH (must be '2.0' or develop)"
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
            echo "Usage: $(basename $0) [-d|--sampledata] [-e|--enterprise] [-g|--github] [--branch=<name>] "
            echo "     [--hostname=<example.dev>] [--admin-user=<admin>] [--admin-email=<email>]"
            echo "     [--admin-first=<name>] [--admin-last=<name>]"
            echo ""
            echo "  -d : --sampledata                       triggers installation of sample data"
            echo "  -e : --enterprise                       uses enterprise meta-packages vs community"
            echo "  -g : --github                           will install via github clone instead of from meta-packages"
            echo "       --hostname=<hostname>              domain of the site (defaults to m2.dev)"
            echo "       --backend-frontname=<frontname>    alphanumerical admin username (defaults to admin)"
            echo "       --admin-user=<admin>               alphanumerical admin username (defaults to admin)"
            echo "       --admin-email=<email>              admin account email address (required input)"
            echo "       --admin-first=<name>               admin user first name (required input)"
            echo "       --admin-name=<name>                admin user last name (required input)"
            echo "       --branch=<branch>                  branch to build the site from (defaults to master)"
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

if [[ ! "$ADMIN_EMAIL" ]] || [[ ! "$ADMIN_FIRST" ]] || [[ ! "$ADMIN_LAST" ]]; then
    >&2 echo "Error: Required admin account information missing. Please use --help for proper usage"
    exit -1
fi

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

        package_name="magento/project-community-edition"
        if [[ $ENTERPRISE ]]; then
            package_name="magento/project-enterprise-edition"
        fi

        composer create-project --repository-url=https://repo.magento.com/ $package_name $SITES_DIR/$HOSTNAME
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

function print_install_info {
    URL_FRONT="http://$HOSTNAME"
    URL_ADMIN="https://$HOSTNAME/$BACKEND_FRONTNAME/admin"

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
print_info_flag=
code=
mysql -e "use $DB_NAME" 2> /dev/null || code="$?"
if [[ $code ]]; then
    echo "==> Creating $DB_NAME database"
    mysql -e "create database $DB_NAME"
    
    echo "==> Running bin/magento setup:install"
    bin/magento setup:install                        \
        --base-url="http://$HOSTNAME"                \
        --base-url-secure="https://$HOSTNAME"        \
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
    bin/magento setup:upgrade -q
fi

echo "==> Flushing magento cache and recompiling"
rm -rf var/di/ var/generation/
bin/magento setup:di:compile-multi-tenant -q
bin/magento setup:static-content:deploy
bin/magento cache:flush

echo "==> Flushing redis service"
redis-cli flushall > /dev/null

if [[ $print_info_flag ]]; then
    echo "==> New site information:"
    print_install_info
    echo ""
fi

echo "Please update any necessary virtual hosts and/or other server configuration!"

cd "$wd"
