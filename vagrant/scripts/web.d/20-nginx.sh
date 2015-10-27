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
# install and configure nginx service

set -e

yum install -y nginx

if [[ -d ./etc/nginx/conf.d/ ]]; then
    cp ./etc/nginx/conf.d/*.conf /etc/nginx/conf.d/
fi

if [[ -d ./etc/nginx/default.d/ ]]; then
    mkdir -p /etc/nginx/default.d
    cp ./etc/nginx/default.d/*.conf /etc/nginx/default.d/
fi
