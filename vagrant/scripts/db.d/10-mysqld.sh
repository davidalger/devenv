# install and configure mysqld service
set -e

if [[ -f ./etc/my.cnf ]]; then
    cp ./etc/my.cnf /etc/my.cnf
fi

mkdir /etc/my.cnf.d/    # won't exist prior to install, and 5.1 doesn't automatically create it
if [[ -d ./etc/my.cnf.d ]] && [[ ! -z "$(ls -1 ./etc/my.cnf.d/)" ]]; then
    cp ./etc/my.cnf.d/*.cnf /etc/my.cnf.d/
fi

yum install -y -q mysql-server

# test for presence of ibdata1 to determine if we have a new install or not
if [[ ! -f /var/lib/mysql/data/ibdata1 ]]; then
    
    # grab our mount parameters for later use and unmount the data directory
    _mount=$(grep " nfs " /etc/mtab | grep /var/lib/mysql/data | awk '{print "mount -t "$3" -o "$4" "$1" "$2}')
    umount /var/lib/mysql/data/
    
    # start servcie to initialize data directory and then stop for remount
    service mysqld start >> $BOOTSTRAP_LOG 2>&1
    service mysqld stop >> $BOOTSTRAP_LOG 2>&1
    
    # move aside new data directory and remount persistent data storage
    mv /var/lib/mysql/data/ /var/lib/mysql/data.new
    mkdir /var/lib/mysql/data
    $_mount
    
    # correct ownership of new files to match mounts owner/group and move into place
    chown -R $(stat -c '%u:%g' /var/lib/mysql/data/) /var/lib/mysql/data.new/
    mv /var/lib/mysql/data.new/* /var/lib/mysql/data/
    rmdir /var/lib/mysql/data.new
    
    # grant root mysql user privileges to connect for other vms and host machine
    service mysqld start >> $BOOTSTRAP_LOG 2>&1
    mysql -uroot -e "
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'dev-host' WITH GRANT OPTION;
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'dev-web' WITH GRANT OPTION;
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'dev-web55' WITH GRANT OPTION;
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'dev-web54' WITH GRANT OPTION;
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'dev-web53' WITH GRANT OPTION;
        FLUSH PRIVILEGES;
    "
    service mysqld stop >> $BOOTSTRAP_LOG 2>&1 # leave it in stopped state
fi
