# install and configure redis service
set -e

yum install -y -q redis

if [[ -f ./etc/redis.conf ]]; then
    cp ./etc/redis.conf /etc/redis.conf
fi
