#!/usr/bin/env bash
##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

set -e

MYSQL_PKG_NAME={{ mysql_server_package_name }}

# Double check this file does not exist prior to running init routine!
if [[ ! -f /var/lib/mysql/ibdata1 ]]; then
    # grab our mount parameters for later use and unmount the data directory
    _mount=$(grep " nfs " /etc/mtab | grep /var/lib/mysql | awk '{print "mount -t "$3" -o "$4" "$1" "$2}')
    umount /var/lib/mysql/

    # Installing the Percona server package installs the data directory contents without starting service
    yum install -y "$MYSQL_PKG_NAME"

    # move aside new data directory and remount persistent data storage
    mv /var/lib/mysql/ /var/lib/mysql.new
    mkdir /var/lib/mysql
    $_mount

    # correct ownership of new files to match mounts owner/group and move into place
    chown -R $(stat -c '%u:%g' /var/lib/mysql/) /var/lib/mysql.new/
    mv /var/lib/mysql.new/* /var/lib/mysql/
    rmdir /var/lib/mysql.new
fi
