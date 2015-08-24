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

## Virtual Machines

### dev-web
This node is setup to run services required to run web applications. Nginx is setup to deliver static assets directly and act as a proxy for anything else. Apache is setup with mod_php to delivery the web application and sits behind Nginx on an internal port. Redis has been setup for a cache data store such that it never writes information to disk.

Run `./bin/vhosts.sh` to generate vhosts for all sites and reload apache.

### dev-db
This node has MySql 5.6.x installed. Since this is a development environment, the root mysql password has been left blank.

## dev-solr
This node does not boot by default and currently does nothing. It is here as a placeholder for running Solr once the provisioning scripts for it are created.
