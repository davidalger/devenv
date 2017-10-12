# Manual Upgrade Procedures

## 2.0.0 from 1.x

### DevEnv Update Procedure

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

    # upgrade local php version to PHP 7 and ensure deps are installed
    brew unlink php56
    /server/vagrant/bin/install.sh

    # remove old dev-* records from /etc/hosts
    sudo perl -i -pe 's/^10\.19\.89\..*dev-.*\n$//' /etc/hosts

    vagrant status
    vagrant up

### Transferring Databases from web70 to web56

    db_name=m1_dev
    db_srchost=dev-web70
    db_dsthost=dev-web56
    mysqldump -h$db_srchost -uroot "$db_name" | pv > "$db_name.sql"
    mysql -h$db_dsthost -uroot -e "drop database if exists $db_name"
    mysql -h$db_dsthost -uroot -e "create database $db_name"
    pv "$db_name.sql" | LC_ALL=C sed 's/\/\*[^*]*DEFINER=[^*]*\*\///g' | mysql -h$db_dsthost -uroot "$db_name"
    rm -vf "$db_name.sql"
    mysql -h$db_srchost -uroot -e "drop database if exists $db_name"

### Re-Importing a Database to Correct DEFINERs

    db_name=m2_demo
    db_host=dev-web70
    mysqldump -h$db_host -uroot "$db_name" | pv > "$db_name.sql"
    mysql -h$db_host -uroot -e "drop database if exists $db_name"
    mysql -h$db_host -uroot -e "create database $db_name"
    pv "$db_name.sql" | LC_ALL=C sed 's/\/\*[^*]*DEFINER=[^*]*\*\///g' | mysql -h$db_host -uroot "$db_name"
    rm -vf "$db_name.sql"

### Correcting Redis Config in env.php or local.xml

Redis is no longer deployed with 16 databases. Sites using different db numbers for obj/fpc/ses storage in redis will need to be updated to use db 0, pointing to the appropriate (std) redis ports for the obj/fpc/ses redis servers.
