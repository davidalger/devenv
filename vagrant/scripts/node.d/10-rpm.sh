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
# configure rpms we need for installing current package versions

set -e
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
