# install mysql client
set -e

source ./scripts/lib/rpm.sh

# determine which version of MySql we are installing
case "$MYSQL_VERSION" in
    
    "" ) # set default of MySql 5.6 if none was specified
        MYSQL_VERSION="56"
        ;&  ## fallthrough to below case, we know it matches
    51 | 56 )
        ;;
    * )
        >&2 echo "Error: Invalid or unsupported MySql version specified"
        exit -1;
esac

if [ "$MYSQL_VERSION" == "56" ]; then
    echo "Installing MySql Community RPM"
    install_rpm http://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm \
        /var/cache/yum/rpms/mysql-community-release-el6-5.noarch.rpm
fi

yum install -y -q mysql

# set default mysql connection info in /etc/my.cnf
echo "[client]
host=dev-db
user=root
password=
" >> /etc/my.cnf
