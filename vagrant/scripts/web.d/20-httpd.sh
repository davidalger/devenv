yum install -y -q httpd

if [[ -d ./etc/httpd/conf.d/ ]]; then
    cp ./etc/httpd/conf.d/*.conf /etc/httpd/conf.d/
fi
perl -pi -e 's/Listen 80//' /etc/httpd/conf/httpd.conf

service httpd start
