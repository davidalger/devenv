# install and configure php

yum --enablerepo=remi --enablerepo=remi-php56 install -y -q php php-cli \
  php-curl php-gd php-intl php-ioncube-loader php-mcrypt php-mhash php-mysqlnd php-xdebug php-xsl \
  sendmail

if [[ -d ./etc/php.d/ ]]; then
    cp ./etc/php.d/*.ini /etc/php.d/
fi
