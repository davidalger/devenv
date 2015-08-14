#!/usr/bin/env bash

set -e
cd /vagrant

echo "Importing RPM GPG Keys"
rpm --import ./etc/RPM-GPG-KEY-CentOS-6.txt
rpm --import ./etc/RPM-GPG-KEY-EPEL-6.txt
rpm --import ./etc/RPM-GPG-KEY-remi.txt

echo "Installing EPEL repository"
yum install -y -q epel-release

echo "Installing Remi's RPM repository"
wget -q http://rpms.famillecollet.com/enterprise/remi-release-6.rpm -O /tmp/remi-release-6.rpm
rpm -K /tmp/remi-release-6.rpm
yum install -y -q /tmp/remi-release-6.rpm || true

echo "Updating installed software..."
yum update -y -q

# execute role specific scripts
for role in "$@"; do
    echo "Configuring $role role"
    
    for script in $(ls -1 scripts/$role.d/*.sh); do
        echo "Running: $role: $(basename $script)"
        ./$script
    done
done
