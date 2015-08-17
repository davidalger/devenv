yum install -y -q nginx

if [[ -d ./etc/httpd/conf.d/ ]]; then
    cp ./etc/nginx/conf.d/*.conf /etc/nginx/conf.d/
fi

service nginx start
