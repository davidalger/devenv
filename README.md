# Development Environment

## Host Setup
* Run the following commands to setup necessary exports and restart nfsd on the host:

        MAPALL="-mapall=$(id -u):$(grep ^admin: /etc/group | cut -d : -f 3)"
        printf "%s\n%s\n" \
            "/Volumes/Server/sites/ -alldirs -network 192.168.235.0 -mask 255.255.255.0 $MAPALL" \
            "/Volumes/Server/mysql/ -alldirs -network 192.168.235.0 -mask 255.255.255.0 $MAPALL" \
            | sudo tee -a /etc/exports > /dev/null
        sudo nfsd restart

* Add the following to the host machine /etc/hosts file:

        ##################################################
        ## Developer Environment
        
        10.19.89.1  dev-host
        10.19.89.10 dev-web
        10.19.89.20 dev-db
        10.19.89.30 dev-solr

* Add the following to the host machine ~/.my.cnf file:

        [client]
        host=dev-db
        user=root
        password=

## Virtual Machines

### dev-web
This node is setup to run services required to run web applications. Nginx is setup to deliver static assets directly and act as a proxy for anything else. Apache is setup with mod_php to delivery the web application and sits behind Nginx on an internal port. Redis has been setup for a cache data store such that it never writes information to disk.

Run `./bin/vhosts.sh` to generate vhosts for all sites and reload apache.

By default this node is configured to install PHP 5.6 from Remi's repository. Different versions of PHP may be chosen by exporting the `VAGRANT_PHP_VERSION` variable on the command line prior to running `vagrant up` for the first time. To switch PHP versions, export the requested PHP version and then run the following to blow away and re-setup your vm:

        vagrant destroy -f web && vagrant up

The requested version of PHP may be specified  via the following environment variable. Valid values are currently 53, 54, 55 and 56 (default). However, PHP 5.3 is not fully supported as there are no packages available for Xdebug or the ionCube loader in the default RPMs used to build PHP 5.3.

        export VAGRANT_PHP_VERSION=56

### dev-db
This node has MySql 5.6.x installed. Since this is a development environment, the root mysql password has been left blank.

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
