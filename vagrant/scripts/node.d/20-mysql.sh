#!/usr/bin/env bash
##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

########################################
# install mysql client

set -e
wd="$(pwd)"

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
    yum install -y /var/cache/yum/rpms/mysql-community-release-el6-5.noarch.rpm
fi

yum install -y mysql

# set default mysql connection info in /etc/my.cnf
echo "[client]
host=dev-db
user=root
password=
" >> /etc/my.cnf
