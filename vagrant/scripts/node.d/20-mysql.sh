# install mysql client
set -e

yum install -y -q mysql

# set default mysql connection info in /etc/my.cnf
echo "[client]
host=dev-db
user=root
password=
" >> /etc/my.cnf
