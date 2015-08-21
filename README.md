# Development Environment

## Host Setup
* Add the following to /etc/exports

        /Volumes/Server/mysql/ -alldirs -network 192.168.235.0 -mask 255.255.255.0 -mapall=root:wheel
        /Volumes/Server/sites/ -alldirs -network 192.168.235.0 -mask 255.255.255.0 -mapall=root:wheel

* Restart nfsd

        # sudo nfsd restart

