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
:: configuring ssl root for cert signing
########################################

if ! [[ -d $SSL_DIR/rootca/ ]]; then
    mkdir -p $SSL_DIR/rootca/{certs,crl,newcerts,private}

    touch $SSL_DIR/rootca/index.txt
    echo 1000 > $SSL_DIR/rootca/serial
fi

# create a CA root certificate if none present
if [[ ! -f $SSL_DIR/rootca/private/ca.key.pem ]]; then
    openssl genrsa -out $SSL_DIR/rootca/private/ca.key.pem 4096

    openssl req -config /etc/openssl/rootca.conf -new -x509 -days 7300 -sha256 -extensions v3_ca \
        -key $SSL_DIR/rootca/private/ca.key.pem \
        -out $SSL_DIR/rootca/certs/ca.cert.pem \
        -subj "/C=US/O=Vagrant DevEnv"

    # alert user where to find root ca cert and what to do with it
    >&2 echo "Note: You must add $SSL_DIR/rootca/certs/ca.cert.pem to trusted certs on host."
fi

# add local CA root to the trusted key-store and enable Shared System Certificates
cp $SSL_DIR/rootca/certs/ca.cert.pem /etc/pki/ca-trust/source/anchors/local-ca.key.pem

update-ca-trust
update-ca-trust enable

# create local ssl private key
[[ ! -d /etc/nginx/ssl ]] && mkdir -p /etc/nginx/ssl
openssl genrsa -out /etc/nginx/ssl/local.key.pem 2048

########################################
:: installing web services
########################################

yum install -y redis sendmail varnish httpd nginx

# install devel tool chain required for php-build to run
yum install -y libxml2-devel httpd-devel libXpm-devel gmp-devel libicu-devel t1lib-devel aspell-devel \
    openssl-devel bzip2-devel libcurl-devel libjpeg-devel libvpx-devel libpng-devel freetype-devel readline-devel \
    libtidy-devel libxslt-devel libmcrypt-devel bison

# TODO: verify each of these extensions is in fact installed
# yum $extra_repos install -y php php-cli php-opcache php-devel \
#     php-mysqlnd php-mhash php-curl php-gd php-intl php-mcrypt php-xsl php-mbstring php-soap php-bcmath php-zip \
#     php-xdebug php-ldap

# setup or update phpenv
if [[ ! -d ~/.phpenv/.git ]]; then
    git clone git://github.com/madumlao/phpenv.git ~/.phpenv
else
    pushd ~/.phpenv
    git pull
    popd
fi

# create phpenv profile for shell
echo 'export PATH="$HOME/.phpenv/bin:$PATH"' >> /etc/profile.d/phpenv.sh
echo 'eval "$(phpenv init -)"' >> /etc/profile.d/phpenv.sh
source /etc/profile.d/phpenv.sh

# setup or update php-build (used by phpenv)
if [[ ! -d $(phpenv root)/plugins/php-build/.git ]]; then
    git clone https://github.com/php-build/php-build $(phpenv root)/plugins/php-build
else
    pushd ~/.phpenv/plugins/php-build
    git pull
    popd
fi

# install latest patch of current php version
php_version=$(echo $PHP_VERSION | sed 's/^[0-9]/&\./')
php_version=$(phpenv install -l | grep -E "^ +$php_version\." | tail -n1)

if [[ ! `phpenv versions --bare | grep "^$php_version$"` ]]; then
    phpenv install $php_version
fi
phpenv global $php_version

# TODO: verify ioncube-loader and xdebug present
# TODO: add custom php configs
# TODO: make sure php sessions work on m2 install process

# # versions prior to PHP 5.6 don't prioritize ini files so some special handling is required
# if [[ -f /etc/php.d/xdebug.ini ]]; then
#     mv /etc/php.d/xdebug.ini /etc/php.d/xdebug.ini.rpmnew
#     touch /etc/php.d/xdebug.ini    # prevents yum update from re-creating the file
# fi
#
# if [[ -f /etc/php.d/ioncube_loader.ini ]]; then
#     mv /etc/php.d/ioncube_loader.ini /etc/php.d/05-ioncube_loader.ini
#     touch /etc/php.d/ioncube_loader.ini     # prevent yum update from re-creating the file
# fi

########################################
:: configuring web services
########################################

perl -pi -e 's/Listen 80//' /etc/httpd/conf/httpd.conf
perl -0777 -pi -e 's#(<Directory "/var/www/html">.*?)AllowOverride None(.*?</Directory>)#$1AllowOverride All$2#s' \
        /etc/httpd/conf/httpd.conf

# disable error index file if installed
[ -f "/var/www/error/noindex.html" ] && mv /var/www/error/noindex.html /var/www/error/noindex.html.disabled

chkconfig redis on
service redis start

chkconfig httpd on
service httpd start

chkconfig varnish on
service varnish start

chkconfig nginx on
service nginx start

########################################
:: installing develop tools
########################################

npm install -g grunt-cli

install_tool https://getcomposer.org/composer.phar /usr/local/bin/composer

install_tool http://files.magerun.net/n98-magerun-latest.phar /usr/local/bin/n98-magerun /usr/local/bin/mr1
install_tool http://files.magerun.net/n98-magerun2-latest.phar /usr/local/bin/n98-magerun2 /usr/local/bin/mr2

ln -s /usr/local/bin/mr1 /usr/local/bin/mr
