# Development Environment

## System Requirements
* Mac OS X 10.9+
* An HFS+ **Case-sensitive** partition mounted at `/Volumes/Server` (opting to not use a case-sensitive partition may result in database issues)

## Environment Setup

1. Retrieve your personal access token from the [GitHub Settings](https://github.com/settings/tokens) page and set this in your current shell by running the following (replacing <your_api_token> with the one you previously retrieved from your GitHub account):

        export HOMEBREW_GITHUB_API_TOKEN=<your_api_token>

2. Run the following to kickstart your environment with common software packages. You will be prompted for your password a few times as this runs to completion

        curl -s https://raw.githubusercontent.com/davidalger/devenv/master/bin/glowbot.py | python

3. Install the vagrant based developer environment on your machine:

        cd /server
        sudo chown $(whoami):admin /server
        git init
        git remote add origin https://github.com/davidalger/devenv.git
        git fetch origin
        git checkout master
        vagrant status
        source /etc/profile

4. Add the following to the `/etc/hosts` file on the host machine using `mate /etc/hosts` or `sudo vi /etc/hosts`:

        ##################################################
        ## Developer Environment
        
        10.19.89.1  dev-host
        10.19.89.10 dev-web
        10.19.89.11 dev-web55
        10.19.89.12 dev-web54
        10.19.89.13 dev-web53
        10.19.89.20 dev-db
        10.19.89.21 dev-db51
        10.19.89.30 dev-solr
        
        ##################################################
        ## Vagrant Sites
        
        10.19.89.10 m2.dev
        

5.  Add the following to the `~/.my.cnf` file on the host machine:

        [client]
        host=dev-db
        user=root
        password=
        
    
    _Note: If there is a `~/.mylogin.cnf` file present on the host, it will supersede this file, potentially breaking things._

6. Install the compass tools used for scss compilation

        sudo gem update --system
        sudo gem install compass

7. Generate an RSA key pair. The generated public key will be used to authenticate remote SSH connections

        ssh-keygen -f ~/.ssh/id_rsa

    *Note: When prompted, enter a memorable passphrase (you’ll need to use it later)*

8. Configure the GitHub API token for composer to use. This may be the same or different than the one created in step 1.

        composer config -g github-oauth.github.com <your_api_token>

8. Run the following to start up the virtual machines. This will take a while on first run

        cd /server
        vagrant up

9. You should be ready to roll! Go ahead and load the [m2.dev](http://m2.dev/) site which should be setup and running inside the virtual machine to make sure everything is working correctly

10. To SSH into the vm, you can use `vcd` or `vcd web` to connect and automatically mirror the working directory if a matching location exists on the vm

## Virtual Machines

### dev-web
This node is setup to run services required to run web applications. Nginx is setup to deliver static assets directly and act as a proxy for anything else. Apache is setup with mod_php to delivery the web application and sits behind Nginx on an internal port. Redis has been setup for a cache data store such that it never writes information to disk.

Run `vhosts.sh` to generate vhosts for all sites and reload apache. This will be automatically run once when the machine is provisioned, and may be subsequently run from `/server/vagrant/bin/vhosts.sh` on either the host or guest environment.

The IP address of this node is fixed at `10.19.89.10`. This IP should be used in `/etc/hosts` on the host machine to facilitate loading applications running within the vm from a browser on the host.

#### PHP Versions

This node has PHP 5.6 from Remi's repository installed. Older versions are available as pre-configured machines, but do not start automatically. To use them, start via `vagrant up web55` or similar. Then configure your local hosts file to point the site needing this specific version of PHP to the correct machine instance.

#### m2.dev
By default one site is automatically created upon machine initialization. It is m2.dev and will run off of the official magento/magento2 repositories develop branch.

To access this site, you'll need to add an entry to your local /etc/hosts file (as with any other site running the vm) and use the following information to login to the admin:

* [http://m2.dev/backend/admin/](http://m2.dev/backend/admin/)
* user: admin
* pass: A123456

### dev-db
This node has MySql 5.6.x installed. Since this is a development environment, the root mysql password has been left blank.

To allow for custom database settings without modifying the default my.cnf file directly, files found at `vagrant/etc/my.cnf.d/*.cnf` will be copied onto this node and are applied via the `!includedir` directive in the `/etc/my.cnf` defaults file. Example use case: create the file `vagrant/etc/my.cnf.d/lower_case_table_names.cnf` with the following contents and then re-provision the vm:

    [mysqld]
    lower_case_table_names = 1

***WARNING:*** Because this node is running the mysqld service and persisting data, attempts to forcefully shutdown (aka run `vagrant destroy`) on the db node will cause data corruption and fail subsequent mysqld start operations unless the vm has first been halted and/or the mysqld service stopped gracefully prior to vm destruction. The recommended sequence to wipe the vm and create from scratch is halt, destroy, then up.

#### MySql Versions

This node has MySql 5.6 from the community MySql RPM installed. Should MySql 5.1 be required, there is a pre-configured machine available, but it will not start by default. Start this machine via `vagrant up db51`. The data directory of this will be kept separate from the MySql 5.6 data in order to preserve data integrity. These machines may be run simultaneously. Configure sites to connect to `dev-db` or `dev-db51` as needed.

## dev-solr
This node does not boot by default and currently does nothing. It is here as a placeholder for running Solr once the provisioning scripts for it are created.

## Development Notes

### Session Storage
It is well recognized that PHP cannot store sessions on an NFS mount. Since /var/www/sites/ is mounted in the vm via an NFS mount, this causes trouble with applications which attempt using a session directory inside the document root. Magento 2 seems to handle this just fine and stores it's sessions in the configured session location. Magento 1 requires one of three workarounds to function:

1. add the following to the `app/etc/local.xml` configuration file inside the `global` node:

        <session_save><![CDATA[files]]></session_save>
        <session_save_path><![CDATA[/var/lib/php/session]]]]></session_save_path>

2. create a soft-link pointing the `var/session` directory to the default php session location

        ln -s /var/lib/php/session var/session

3. use an alternative session storage mechanism such as redis or memcached

## VMWare Provider

Using VMWare Fusion is a supported (but non-default) setup. There are additional steps involved to use it due to differences in how Virtual Box and VMX configure network interfaces and handle NFS mounts.

For NFS mounts to function, run the following to add the necessary exports to your `/etc/exports` file on the host machine and restart nfsd:

        MAPALL="-mapall=$(id -u):$(grep ^admin: /etc/group | cut -d : -f 3)"
        MOUNT_DIR="$(readlink /server || echo /server)"
        printf "%s\n%s\n" \
            "$MOUNT_DIR/sites/ -alldirs -network 192.168.235.0 -mask 255.255.255.0 $MAPALL" \
            "$MOUNT_DIR/mysql/ -alldirs -network 192.168.235.0 -mask 255.255.255.0 $MAPALL" \
            | sudo tee -a /etc/exports > /dev/null
        sudo nfsd restart
