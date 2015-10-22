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
# install and configure httpd service

set -e

yum install -y httpd

if [[ -d ./etc/httpd/conf.d/ ]]; then
    cp ./etc/httpd/conf.d/*.conf /etc/httpd/conf.d/
fi
perl -pi -e 's/Listen 80//' /etc/httpd/conf/httpd.conf

if [[ -f "/var/www/error/noindex.html" ]]; then
    mv /var/www/error/noindex.html /var/www/error/noindex.html.disabled
fi
