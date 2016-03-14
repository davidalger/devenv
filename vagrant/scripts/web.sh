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
source ./scripts/lib/vars.sh

########################################
# configure ssl roots for use with https

ssldir=$SHARED_DIR/ssl
if ! [[ -d $ssldir ]]; then
    mkdir -p $ssldir/rootca/{certs,crl,newcerts,private}

    touch $ssldir/rootca/index.txt
    echo 1000 > $ssldir/rootca/serial
fi

sslconfig=$VAGRANT_DIR/etc/openssl/rootca.conf

########################################
# configure ssl root CA

if [[ ! -f $ssldir/rootca/private/ca.key.pem ]]; then
    echo "==> Creating root CA"

    openssl genrsa -out $ssldir/rootca/private/ca.key.pem 4096

    openssl req -config $sslconfig -new -x509 -days 7300 -sha256 -extensions v3_ca \
        -key $ssldir/rootca/private/ca.key.pem \
        -out $ssldir/rootca/certs/ca.cert.pem \
        -subj "/C=US/O=Vagrant DevEnv"

    echo "==> Root CA created"

    # alert user where to find root ca cert and what to do with it
    >&2 echo "NOTE: you must add $ssldir/rootca/certs/ca.cert.pem to trusted certs on host."
fi

# create local ssl private key
[ ! -f $ssldir/local.key.pem ] && openssl genrsa -out $ssldir/local.key.pem 2048

########################################
# install services and tools

yum install -y redis sendmail varnish httpd nginx
npm install -g grunt-cli

########################################
# configure httpd service

perl -pi -e 's/Listen 80//' /etc/httpd/conf/httpd.conf
perl -0777 -pi -e 's#(<Directory "/var/www/html">.*?)AllowOverride None(.*?</Directory>)#$1AllowOverride All$2#s' \
        /etc/httpd/conf/httpd.conf

# disable error index file if installed
[ -f "/var/www/error/noindex.html" ] && mv /var/www/error/noindex.html /var/www/error/noindex.html.disabled

########################################
# install and configure php

# install php and cross-version dependencies
yum $extra_repos install -y php php-cli php-curl php-gd php-intl php-mcrypt php-xsl php-mbstring php-soap php-bcmath

# install mysql support for php 5.3
[[ "$PHP_VERSION" = 53 ]] && yum $extra_repos install -y php-mysql

# install packages only available on 5.4 or newer (available from remi rpms)
if [[ "$PHP_VERSION" > 53 ]]; then
    yum $extra_repos install -y php-mysqlnd php-xdebug php-mhash php-opcache

    # older versions of php don't prioritize ini files by default
    [[ "$PHP_VERSION" < 56 ]] && mv /etc/php.d/xdebug.ini /etc/php.d/15-xdebug.ini
    [[ "$PHP_VERSION" < 56 ]] && mv /etc/php.d/ioncube_loader.ini /etc/php.d/05-ioncube_loader.ini

    # the ioncube-loader package for php7 does not exist yet
    [[ "$PHP_VERSION" < 70 ]] && yum $extra_repos install -y php-ioncube-loader
fi

# phpredis does not yet have php7 support
[[ "$PHP_VERSION" < 70 ]] && yum $extra_repos install -y php-pecl-redis

# remove xdebug config if xdebug not installed
[ ! -f /usr/lib64/php/modules/xdebug.so ] && rm -f /etc/php.d/15-xdebug.ini

########################################
# download and install composer into vm

composer_url="https://getcomposer.org/download/1.0.0-alpha11/composer.phar"
composer_home="$SHARED_DIR/composer"
composer_path="/usr/local/bin/composer"

mkdir -p "$composer_home"
pushd "$composer_home"

wget -qN "$composer_url" || true
if [[ ! -f "$composer_home/composer.phar" ]]; then
    >&2 echo "Error: failed to retrieve composer.phar and local cache is empty"
    exit -1;
fi
cp "$composer_home/composer.phar" "$composer_path"
chmod +x "$composer_path"

popd

########################################
# download and install composer into vm

function install_mr {
    download_url="$1"
    install_path="$2"
    shortcut_tla="$3"

    file_name="$(basename $download_url)"
    pushd "$SHARED_DIR"

    wget -qN "$download_url" || true
    if [[ ! -f "$SHARED_DIR/$file_name" ]]; then
        >&2 echo "Error: failed to retrieve $file_name and local cache is empty"
    fi

    cp "$SHARED_DIR/$file_name" "$install_path"
    chmod +x "$install_path"

    ln -s "$install_path" "$shortcut_tla"

    popd
}

install_mr http://files.magerun.net/n98-magerun-latest.phar /usr/local/bin/n98-magerun /usr/local/bin/mr1
install_mr http://files.magerun.net/n98-magerun2-latest.phar /usr/local/bin/n98-magerun2 /usr/local/bin/mr2

ln -s /usr/local/bin/mr1 /usr/local/bin/mr
