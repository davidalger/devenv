# setup misc generic node configuration

if [[ -f ./etc/hosts ]]; then
    cp ./etc/hosts /etc/hosts
fi

if [[ -d ./etc/profile.d/ ]]; then
    cp ./etc/profile.d/*.sh /etc/profile.d/
fi
