# configure rpms we need for installing current package versions
set -e

function install_rpm {
    if [[ -z "$1" ]] || [[ -z "$2" ]]; then
        echo "usage: install_rpm <rpm_url> <rpm_path>"
        exit 1;
    fi
    rpm_url="$1"
    rpm_path="$2"
    
    # download from remote and verify signature if not present in local cache
    if [[ ! -f "$rpm_path" ]]; then
        if [[ ! -d "$(dirname $rpm_path)" ]]; then
            mkdir -p "$(dirname $rpm_path)"
        fi
        wget -q "$rpm_url" -O "$rpm_path"
        rpm -K "$rpm_path"
    fi
    
    yum install -y -q "$rpm_path" || true
}

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
yum install -y -q epel-release

echo "Installing MySql Community RPM"
install_rpm http://repo.mysql.com/mysql-community-release-el6-5.noarch.rpm \
    /var/cache/yum/rpms/mysql-community-release-el6-5.noarch.rpm

echo "Installing Remi's RPM repository"
install_rpm http://rpms.famillecollet.com/enterprise/remi-release-6.rpm \
    /var/cache/yum/rpms/remi-release-6.rpm

echo "Updating installed software"
yum update -y -q
