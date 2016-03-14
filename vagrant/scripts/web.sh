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

ssldir=$SHARED_DIR/ssl
configpath=$VAGRANT_DIR/etc/openssl/rootca.conf

########################################
# configure ssl shared dir

if ! [[ -d $ssldir ]]; then
    mkdir -p $ssldir/rootca

    mkdir $ssldir/rootca/certs
    mkdir $ssldir/rootca/crl
    mkdir $ssldir/rootca/newcerts
    mkdir $ssldir/rootca/private

    touch $ssldir/rootca/index.txt
    echo 1000 > $ssldir/rootca/serial
fi

########################################
# configure ssl root CA

if [[ -f $ssldir/rootca/private/ca.key.pem ]]; then
    echo "==> Existing root CA found"
else
    echo "==> Creating root CA"

    openssl genrsa -out $ssldir/rootca/private/ca.key.pem 4096

    openssl req -config $configpath -new -x509 -days 7300 -sha256 -extensions v3_ca \
        -key $ssldir/rootca/private/ca.key.pem \
        -out $ssldir/rootca/certs/ca.cert.pem \
        -subj "/C=US/O=Vagrant DevEnv"

    echo "==> Root CA created"

    # alert user where to find root ca cert and what to do with it
    >&2 echo "NOTE: you must add $ssldir/rootca/certs/ca.cert.pem to trusted certs on host."
fi

########################################
# configure local ssl private key

if [[ -f $ssldir/local.key.pem ]]; then
    echo "==> Existing local ssl private key found"
else
    echo "==> Creating local SSL private key"

    openssl genrsa -out $ssldir/local.key.pem 2048

    echo "==> Local SSL private key created"
fi

########################################
# install and configure httpd service

yum install -y httpd

if [[ -d ./etc/httpd/conf.d/ ]]; then
    cp ./etc/httpd/conf.d/*.conf /etc/httpd/conf.d/
fi

perl -pi -e 's/Listen 80//' /etc/httpd/conf/httpd.conf
perl -0777 -pi -e 's#(<Directory "/var/www/html">.*?)AllowOverride None(.*?</Directory>)#$1AllowOverride All$2#s' \
        /etc/httpd/conf/httpd.conf

if [[ -f "/var/www/error/noindex.html" ]]; then
    mv /var/www/error/noindex.html /var/www/error/noindex.html.disabled
fi

########################################
# install and configure nginx service

yum install -y nginx

if [[ -d ./etc/nginx/conf.d/ ]]; then
    cp ./etc/nginx/conf.d/*.conf /etc/nginx/conf.d/
fi

if [[ -d ./etc/nginx/default.d/ ]]; then
    mkdir -p /etc/nginx/default.d
    cp ./etc/nginx/default.d/*.conf /etc/nginx/default.d/
fi

########################################
# install and configure php

# determine which version of php we are installing and determine which extra RPMs are needed
case "$PHP_VERSION" in
    
    "" ) # set default of PHP 5.6 if none was specified
        PHP_VERSION="56"
        ;&  ## fallthrough to below case, we know it matches
    55 | 56 | 70 )
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
    php-curl php-gd php-intl php-mcrypt php-xsl php-mbstring php-soap php-bcmath

# phpredis does not yet have php7 support
if [[ "$PHP_VERSION" < 70 ]]; then
    yum $extra_repos install -y php-pecl-redis
fi

# remi repo provides these extra packages for 5.4 and newer, so skip them on 5.3 setup
if [[ "$PHP_VERSION" > 53 ]]; then
    yum $extra_repos install -y php-mysqlnd php-xdebug php-mhash php-opcache
    
    # the ioncube-loader package for php7 does not exist yet
    if [[ "$PHP_VERSION" < 70 ]]; then
        yum $extra_repos install -y php-ioncube-loader
    fi
    
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

########################################
# install and configure redis service

yum install -y redis

if [[ -f ./etc/redis.conf ]]; then
    cp ./etc/redis.conf /etc/redis.conf
fi

########################################
# install and configure sendmail

yum install -y sendmail

########################################
# install and configure varnishd service

yum install -y varnish

if [[ -f ./etc/varnish/default.vcl ]]; then
    cp ./etc/varnish/default.vcl /etc/varnish/default.vcl
fi

########################################
# download and install composer into vm

wd="$(pwd)"
composer_url="https://getcomposer.org/download/1.0.0-alpha11/composer.phar"
composer_home="$SHARED_DIR/composer"
composer_path="/usr/local/bin/composer"

mkdir -p "$composer_home"
cd "$composer_home"

wget -qN "$composer_url" || true
if [[ ! -f "$composer_home/composer.phar" ]]; then
    >&2 echo "Error: failed to retrieve composer.phar and local cache is empty"
    exit -1;
fi
cp "$composer_home/composer.phar" "$composer_path"
chmod +x "$composer_path"

cd "$wd"

########################################
# install grunt cli tools

npm install -g grunt-cli

########################################
# download and install composer into vm

wd="$(pwd)"
function install_mr {
    download_url="$1"
    install_path="$2"
    shortcut_tla="$3"

    file_name="$(basename $download_url)"
    cd "$SHARED_DIR"

    wget -qN "$download_url" || true
    if [[ ! -f "$SHARED_DIR/$file_name" ]]; then
        >&2 echo "Error: failed to retrieve $file_name and local cache is empty"
    fi

    cp "$SHARED_DIR/$file_name" "$install_path"
    chmod +x "$install_path"

    ln -s "$install_path" "$shortcut_tla"
}

install_mr http://files.magerun.net/n98-magerun-latest.phar /usr/local/bin/n98-magerun /usr/local/bin/mr1
install_mr http://files.magerun.net/n98-magerun2-latest.phar /usr/local/bin/n98-magerun2 /usr/local/bin/mr2

ln -s /usr/local/bin/mr1 /usr/local/bin/mr

cd "$wd"
