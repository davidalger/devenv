# configure rpms we need for installing current package versions
set -e

source ./scripts/lib/rpm.sh

echo "Setting up yum cache"
if [[ -f ./etc/yum.conf ]]; then
    cp ./etc/yum.conf /etc/yum.conf
fi

echo "Importing RPM GPG Keys"
rpm --import ./etc/keys/RPM-GPG-KEY-CentOS-6.txt
rpm --import ./etc/keys/RPM-GPG-KEY-EPEL-6.txt
rpm --import ./etc/keys/RPM-GPG-KEY-MySql.txt
rpm --import ./etc/keys/RPM-GPG-KEY-remi.txt

echo "Installing EPEL repository"
yum install -y epel-release

echo "Installing Remi's RPM repository"
install_rpm http://rpms.famillecollet.com/enterprise/remi-release-6.rpm \
    /var/cache/yum/rpms/remi-release-6.rpm

echo "Updating installed software"
yum update -y -q
