# Manual Upgrade Procedures

## 2.0.0 from 1.x

    cd /server

    vagrant halt
    vagrant destroy -f

    git fetch
    git checkout master
    git reset --hard origin/master

    brew update
    brew cask reinstall vagrant
    brew cask reinstall virtualbox

    gem install pkg-config -v "~> 1.1.7"
    vagrant plugin repair

    if [[ ! -d /server/mysql/web70 ]]; then
        mv /server/mysql/data /server/mysql/web70
    fi

    # reconfigure custom webroots
    perl -pi -e 's#/server/sites/#/var/www/sites/#' /server/sites/*/.*.conf

    # strip out ssl_ciphers and ssl_protocols
    perl -pi -e 's#^\s+ssl_(ciphers|protocols)\s+.*;\n##' /server/sites/*/.nginx.conf

    # reset the shared npm/yum cache
    rm -rf /server/.shared/{yum,npm}

    vagrant status
    vagrant up
