#!/usr/bin/env bash
##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

set -e

source ./scripts/lib/utils.sh

########################################
:: configuring guest machine provider
########################################

# configure VM Ware tools to automatically rebuild missing VMX kernel modules upon boot
# see: https://github.com/mitchellh/vagrant/issues/4362#issuecomment-52589577
#
if [[ -f /etc/vmware-tools/locations ]]; then
    sed -i -re 's/^answer (AUTO_KMODS_ENABLED|AUTO_KMODS_ENABLED_ANSWER) no$/answer \1 yes/' /etc/vmware-tools/locations
fi

########################################
:: configuring rpms needed for install
########################################

# enable rpm caching and set higher metadata cache
sed -i 's/keepcache=0/keepcache=1\nmetadata_expire=24h/' /etc/yum.conf

# append exclude rule to avoid updating the yum tool and kernel packages (causes issues with VM Ware tools on re-create)
printf "\n\nexclude=yum nfs-utils kernel*\n" >> /etc/yum.conf

# import gpg keys before installing anything
rpm --import ./etc/keys/RPM-GPG-KEY-CentOS-6.txt
rpm --import ./etc/keys/RPM-GPG-KEY-EPEL-6.txt
rpm --import ./etc/keys/RPM-GPG-KEY-MySql.txt
rpm --import ./etc/keys/RPM-GPG-KEY-remi.txt
rpm --import ./etc/keys/RPM-GPG-KEY-nginx.txt
rpm --import ./etc/keys/RPM-GPG-KEY-Varnish.txt

# install wget since it's not in Digital Ocean base image
yum install -y wget

if [[ ! -d /var/cache/yum/rpms ]]; then
    mkdir -p /var/cache/yum/rpms
fi
pushd /var/cache/yum/rpms

# redirect stderr -> stdin so info is logged
# ignore error codes for offline cache (where file does not exist the following commands should fail on rpm --checksig)
wget --timestamp http://rpms.famillecollet.com/enterprise/remi-release-6.rpm 2>&1 || true
wget --timestamp http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm 2>&1 || true
wget --timestamp https://repo.varnish-cache.org/redhat/varnish-4.1.el6.rpm 2>&1 || true
wget --timestamp http://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm 2>&1 || true

rpm --checksig remi-release-6.rpm
rpm --checksig nginx-release-centos-6-0.el6.ngx.noarch.rpm
rpm --checksig varnish-4.1.el6.rpm
rpm --checksig mysql-community-release-el6-5.noarch.rpm

yum install -y epel-release
yum install -y remi-release-6.rpm
yum install -y nginx-release-centos-6-0.el6.ngx.noarch.rpm
yum install -y varnish-4.1.el6.rpm

## only setup mysql community rpm if mysql 56 is requested
[ "$MYSQL_VERSION" == "56" ] && yum install -y /var/cache/yum/rpms/mysql-community-release-el6-5.noarch.rpm

popd

########################################
:: updating currently installed packages
########################################

yum update -y

########################################
:: installing npm package manager
########################################

yum install -y npm --disableexcludes=all
npm -g config set cache /var/cache/npm
npm -g config set cache-min 86400

# fix npm install problem by overwriting symlink with copy of linked version
if [[ -L /usr/lib/node_modules/inherits ]]; then
    inherits="$(readlink -f /usr/lib/node_modules/inherits)"
    rm -f /usr/lib/node_modules/inherits
    cp -r "$inherits" /usr/lib/node_modules/inherits
fi

########################################
:: setting zone info to match host zone
########################################

if [[ -f "$HOST_ZONEINFO" ]]; then
    if [[ -f /etc/localtime ]]; then
        mv /etc/localtime /etc/localtime.bak
    elif [[ -L /etc/localtime ]]; then
        rm /etc/localtime
    fi
    ln -s "$HOST_ZONEINFO" /etc/localtime
fi

########################################
:: installing generic guest tooling
########################################

yum install -y bash-completion bc man git rsync mysql
rsync -av --ignore-existing ./guest/bin/ /usr/local/bin/

########################################
:: installing configuration into /etc
########################################

rsync -av ./guest/etc/ /etc/
git config --global core.excludesfile /etc/.gitignore_global
