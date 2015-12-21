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

# note: this should also happen in node.d
if [[ -f ./etc/yum.conf ]]; then
    cp ./etc/yum.conf /etc/yum.conf
fi

rpm --import ./etc/keys/RPM-GPG-KEY-Varnish.txt

install_rpm https://repo.varnish-cache.org/redhat/varnish-4.1.el6.rpm \
    /var/cache/yum/rpms/varnish-4.1el6.rpm
