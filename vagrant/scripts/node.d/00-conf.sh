# setup misc generic node configuration

# configure VM Ware tools to automatically rebuild missing VMW kernel modules upon boot
# see: https://github.com/mitchellh/vagrant/issues/4362#issuecomment-52589577
#
if [[ -f /etc/vmware-tools/locations ]]; then
    sed -i -re 's/^answer (AUTO_KMODS_ENABLED|AUTO_KMODS_ENABLED_ANSWER) no$/answer \1 yes/' /etc/vmware-tools/locations
fi

if [[ -f ./etc/hosts ]]; then
    cp ./etc/hosts /etc/hosts
fi

if [[ -d ./etc/profile.d/ ]]; then
    cp ./etc/profile.d/*.sh /etc/profile.d/
fi
