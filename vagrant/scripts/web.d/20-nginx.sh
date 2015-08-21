# install and configure nginx service

yum install -y -q nginx

if [[ -d ./etc/nginx/conf.d/ ]]; then
    cp ./etc/nginx/conf.d/*.conf /etc/nginx/conf.d/
fi

if [[ -d ./etc/nginx/default.d/ ]]; then
    cp ./etc/nginx/default.d/*.conf /etc/nginx/default.d/
fi
