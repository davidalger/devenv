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
# install and configure php

set -e

# determine which version of php we are installing and determine which extra RPMs are needed
case "$PHP_VERSION" in
    
    "" ) # set default of PHP 5.6 if none was specified
        PHP_VERSION="56"
        ;&  ## fallthrough to below case, we know it matches
    55 | 56 )
        extra_repos="--enablerepo=remi --enablerepo=remi-php${PHP_VERSION}"
        ;;
    54 )
        extra_repos="--enablerepo=remi"
        >&2 echo "Warning: PHP 5.4 is deprecated"
        ;;
    53 )
        extra_repos=""
        >&2 echo "Warning: PHP 5.3 is deprecated, some things may not work properly..."
        ;;
    * )
        >&2 echo "Error: Invalid or unsupported PHP version specified"
        exit -1;
esac

# install php and cross-version dependencies
yum $extra_repos install -y php php-cli \
    php-curl php-gd php-intl php-mcrypt php-pecl-redis php-xsl php-mbstring php-soap php-bcmath

# remi repo provides these extra packages for 5.4 and newer, so skip them on 5.3 setup
if [[ "$PHP_VERSION" > 53 ]]; then
    yum $extra_repos install -y php-ioncube-loader php-mysqlnd php-xdebug php-mhash
    
    if [[ "$PHP_VERSION" < 56 ]]; then
        mv /etc/php.d/xdebug.ini /etc/php.d/15-xdebug.ini
        mv /etc/php.d/ioncube_loader.ini /etc/php.d/05-ioncube_loader.ini
    fi
else
    yum $extra_repos install -y php-mysql
fi

# copy in our custom configuration files
if [[ -d ./etc/php.d/ ]]; then
    cp ./etc/php.d/*.ini /etc/php.d/
fi

# remove xdebug config if xdebug.so file is not present
if [[ ! -f /usr/lib64/php/modules/xdebug.so ]]; then
    rm -f /etc/php.d/15-xdebug.ini
fi
