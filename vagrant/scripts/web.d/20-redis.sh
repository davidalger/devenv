# install and configure redis service

yum install -y -q redis

if [[ -f ./etc/redis.conf ]]; then
    cp ./etc/redis.conf /etc/redis.conf
fi
