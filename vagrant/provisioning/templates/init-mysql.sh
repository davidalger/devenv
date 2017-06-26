#!/usr/bin/env bash
##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

set -eu

MYSQL_PKG_NAME={{ mysql_server_package_name }}

# Evaluate if package is installed or not
MYSQL_PKG_INSTALLED=$(yum -q list installed "$MYSQL_PKG_NAME" &>/dev/null && echo true || echo false )
echo $MYSQL_PKG_INSTALLED

# Evaluate if mysql data files exist
MYSQL_DATA_EXISTS=$([[ -f /var/lib/mysql/ibdata1 ]] && echo true || echo false )
echo $MYSQL_DATA_EXISTS

# Double check this file does not exist prior to running init routine!
if [[ ${MYSQL_DATA_EXISTS} == false || ${MYSQL_PKG_INSTALLED} == false ]]; then
    # grab our mount parameters for later use and unmount the data directory
    _mount=$(grep " nfs " /etc/mtab | grep /var/lib/mysql | awk '{print "mount -t "$3" -o "$4" "$1" "$2}')
    
    if [[ ${MYSQL_DATA_EXISTS} == false ]]; then
        umount /var/lib/mysql/

        # Installing the Percona server package installs the data directory contents without starting service
        yum install -y "$MYSQL_PKG_NAME"

        # Additional support needed for MySQL 5.7+ as it install more securely by default
        # Start MySQL (so that it creates the initial files correctly), reset passwords, then stop MySQL
        systemctl start mysqld
    
        # capture generated root password from mysqld logs (from first start)
        MYSQL_ROOT_PASS=$(perl -0777 -ne 'print "$&\n" if /(?<=password is generated for root\@localhost: ).+/' /var/log/mysqld.log)
        echo "
        [client]
        password = ${MYSQL_ROOT_PASS}
        user = root
        " > /root/.my.cnf
    
        # since generated password for root requires it to be changed
        # generate new password and reset root password
        MYSQL_NEW_ROOT_PASS=$(openssl rand -base64 16)
        mysql --connect-expired-password  -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_NEW_ROOT_PASS}';"
        echo "
        [client]
        password = ${MYSQL_NEW_ROOT_PASS}
        user = root
        " > /root/.my.cnf
    else
        umount /var/lib/mysql/

        # Installing the Percona server package installs the data directory contents without starting service
        yum install -y "$MYSQL_PKG_NAME"
    fi
    
    systemctl stop mysqld
    
    # move aside new data directory and remount persistent data storage
    mv /var/lib/mysql/ /var/lib/mysql.new
    mkdir /var/lib/mysql
    $_mount
    
    
    if [[ ${MYSQL_DATA_EXISTS} == false ]]; then
        # Might as well also save the .my.cnf with the generated password somwhere that it will persist
        cp /root/.my.cnf /var/lib/mysql/
    
        # Let's set it up for the vagrant user also
        cp /root/.my.cnf ~vagrant/
        
        # correct ownership of new files to match mounts owner/group and move into place
        chown -R $(stat -c '%u:%g' /var/lib/mysql/) /var/lib/mysql.new/
    
        # Move any existing files back to mounted nfs share
        [[ $(ls -A /var/lib/mysql.new) ]] && mv /var/lib/mysql.new/* /var/lib/mysql/

        rmdir /var/lib/mysql.new
    else
        # Get the persisted .my.cnf
        cp /var/lib/mysql/.my.cnf /root/
    
        # Let's set it up for the vagrant user also
        cp /root/.my.cnf ~vagrant/
    
        rm -rf /var/lib/mysql.new
    fi
fi
