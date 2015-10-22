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

source ./scripts/lib/rpm.sh

if [[ -f ./etc/yum.conf ]]; then
    cp ./etc/yum.conf /etc/yum.conf
fi

rpm --import ./etc/keys/RPM-GPG-KEY-CentOS-6.txt
rpm --import ./etc/keys/RPM-GPG-KEY-EPEL-6.txt
rpm --import ./etc/keys/RPM-GPG-KEY-MySql.txt
rpm --import ./etc/keys/RPM-GPG-KEY-remi.txt
rpm --import ./etc/keys/RPM-GPG-KEY-nginx.txt

yum install -y epel-release

install_rpm http://rpms.famillecollet.com/enterprise/remi-release-6.rpm \
    /var/cache/yum/rpms/remi-release-6.rpm

install_rpm http://nginx.org/packages/centos/6/noarch/RPMS/nginx-release-centos-6-0.el6.ngx.noarch.rpm \
    /var/cache/yum/rpms/nginx-release-6.rpm

yum update -y -q
