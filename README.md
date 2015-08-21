# Development Environment

## Host Setup
* Run the following commands to setup necessary exports and restart nfsd on the host:

        MAPALL="-mapall=$(id -u):$(grep ^admin: /etc/group | cut -d : -f 3)"
        printf "%s\n%s\n" \
            "/Volumes/Server/sites/ -alldirs -network 192.168.235.0 -mask 255.255.255.0 $MAPALL" \
            "/Volumes/Server/mysql/ -alldirs -network 192.168.235.0 -mask 255.255.255.0 $MAPALL" \
            | sudo tee -a /etc/exports > /dev/null
        sudo nfsd restart
