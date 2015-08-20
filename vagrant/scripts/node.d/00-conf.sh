# setup misc generic node configuration

# configure VM Ware tools to automatically rebuild missing VMX kernel modules upon boot
# see: https://github.com/mitchellh/vagrant/issues/4362#issuecomment-52589577
#
if [[ -f /etc/vmware-tools/locations ]]; then
    sed -i -re 's/^answer (AUTO_KMODS_ENABLED|AUTO_KMODS_ENABLED_ANSWER) no$/answer \1 yes/' /etc/vmware-tools/locations
fi

# import hosts file to maintain named refs for machine IPs
if [[ -f ./etc/hosts ]]; then
    cp ./etc/hosts /etc/hosts
fi

# import all available profile.d scripts to configure bash
if [[ -d ./etc/profile.d/ ]]; then
    cp ./etc/profile.d/*.sh /etc/profile.d/
fi

# set default mysql connection info in /etc/my.cnf
echo "[client]
host=dev-db
user=root
password=
" >> /etc/my.cnf
