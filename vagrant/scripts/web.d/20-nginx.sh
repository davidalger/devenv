# install and configure nginx service
set -e

yum install -y nginx

if [[ -d ./etc/nginx/conf.d/ ]]; then
    cp ./etc/nginx/conf.d/*.conf /etc/nginx/conf.d/
fi

if [[ -d ./etc/nginx/default.d/ ]]; then
    cp ./etc/nginx/default.d/*.conf /etc/nginx/default.d/
fi
