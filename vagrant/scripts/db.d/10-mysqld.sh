# install and configure mysqld service

if [[ -f ./etc/my.cnf ]]; then
    cp ./etc/my.cnf /etc/my.cnf
fi

yum install -y -q mysql-server
service mysqld start || true        # let the script proceed, even if start issues error code
chkconfig mysqld on

mysql -uroot -e "
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'10.19.89.1' WITH GRANT OPTION;
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'dev-web' WITH GRANT OPTION;
    FLUSH PRIVILEGES;
"
