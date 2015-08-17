# configure rpms we need for installing current package versions

echo "Importing RPM GPG Keys"
rpm --import ./etc/keys/RPM-GPG-KEY-CentOS-6.txt
rpm --import ./etc/keys/RPM-GPG-KEY-EPEL-6.txt
rpm --import ./etc/keys/RPM-GPG-KEY-remi.txt

echo "Installing EPEL repository"
yum install -y -q epel-release

echo "Installing Remi's RPM repository"
wget -q http://rpms.famillecollet.com/enterprise/remi-release-6.rpm -O /tmp/remi-release-6.rpm
rpm -K /tmp/remi-release-6.rpm
yum install -y -q /tmp/remi-release-6.rpm || true
rm -f /tmp/remi-release-6.rpm

echo "Updating installed software..."
yum update -y -q
