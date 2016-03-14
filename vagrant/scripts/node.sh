#!/usr/bin/env bash
##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

set -e

########################################
# setup misc generic node configuration

# configure VM Ware tools to automatically rebuild missing VMX kernel modules upon boot
# see: https://github.com/mitchellh/vagrant/issues/4362#issuecomment-52589577
#
if [[ -f /etc/vmware-tools/locations ]]; then
    sed -i -re 's/^answer (AUTO_KMODS_ENABLED|AUTO_KMODS_ENABLED_ANSWER) no$/answer \1 yes/' /etc/vmware-tools/locations
fi

# import hosts file to maintain named refs for machine IPs
if [[ -f ./etc/hosts ]]; then
    cp ./etc/hosts /etc/hosts
fi

# import all available profile.d scripts to configure bash
if [[ -d ./etc/profile.d/ ]]; then
    cp ./etc/profile.d/*.sh /etc/profile.d/
fi

# set zone info to match host if possible
if [[ -f "$HOST_ZONEINFO" ]]; then
    if [[ -f /etc/localtime ]]; then
        mv /etc/localtime /etc/localtime.bak
    elif [[ -L /etc/localtime ]]; then
        rm /etc/localtime
    fi
    ln -s "$HOST_ZONEINFO" /etc/localtime
fi

########################################
# configure rpms we need for installing current package versions
wd="$(pwd)"

if [[ -f ./etc/yum.conf ]]; then
    cp ./etc/yum.conf /etc/yum.conf
fi

rpm --import ./etc/keys/RPM-GPG-KEY-CentOS-6.txt
rpm --import ./etc/keys/RPM-GPG-KEY-EPEL-6.txt
rpm --import ./etc/keys/RPM-GPG-KEY-MySql.txt
rpm --import ./etc/keys/RPM-GPG-KEY-remi.txt
rpm --import ./etc/keys/RPM-GPG-KEY-nginx.txt
rpm --import ./etc/keys/RPM-GPG-KEY-Varnish.txt

yum install -y wget

if [[ ! -d /var/cache/yum/rpms ]]; then
    mkdir -p /var/cache/yum/rpms
fi
cd /var/cache/yum/rpms

# redirect stderr -> stdin so info is logged
# ignore error codes for offline cache (where file does not exist the following commands should fail the script instead)
wget --timestamp http://rpms.famillecollet.com/enterprise/remi-release-6.rpm 2>&1 || true
wget --timestamp http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm 2>&1 || true
wget --timestamp https://repo.varnish-cache.org/redhat/varnish-4.1.el6.rpm 2>&1 || true
wget --timestamp http://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm 2>&1 || true    # install in 20-mysql.sh

rpm --checksig remi-release-6.rpm
rpm --checksig nginx-release-centos-6-0.el6.ngx.noarch.rpm
rpm --checksig varnish-4.1.el6.rpm
rpm --checksig mysql-community-release-el6-5.noarch.rpm

yum install -y epel-release
yum install -y remi-release-6.rpm
yum install -y nginx-release-centos-6-0.el6.ngx.noarch.rpm
yum install -y varnish-4.1.el6.rpm

yum update -y

cd "$wd"

########################################
# install and configure npm

yum install -y npm --disableexcludes=all
npm -g config set cache /var/cache/npm

# fix npm install problem by overwriting symlink with copy of linked version
if [[ -L /usr/lib/node_modules/inherits ]]; then
    inherits="$(readlink -f /usr/lib/node_modules/inherits)"
    rm -f /usr/lib/node_modules/inherits
    cp -r "$inherits" /usr/lib/node_modules/inherits
fi

########################################
# setup bash completion

yum install -y bash-completion

########################################
# install man page tool so folks can actually use man pages

yum install -y man

########################################
# install and configure git

yum install -y git
git config --global core.excludesfile /etc/.gitignore_global

########################################
# install mysql client
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
