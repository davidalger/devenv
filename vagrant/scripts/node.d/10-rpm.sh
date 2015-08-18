# configure rpms we need for installing current package versions

echo "Setting up yum cache"
if [[ -f ./etc/yum.conf ]]; then
    cp ./etc/yum.conf /etc/yum.conf
fi

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

echo "Priming metadata cache"
yum makecache --enablerepo=remi --enablerepo=remi-php56

echo "Updating installed software"
yum update -y -q yum || true        # ignore result code to work around cpio failure caused by synced cache dir
yum update -y -q -x yum             # keep our software up-to-date
