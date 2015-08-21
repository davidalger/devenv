# Development Environment

## Host Setup
* Add the following line to /etc/exports and restart nfsd by running `sudo nfsd restart`

        "/Volumes/Server/" -alldirs -network 192.168.235.0 -mask 255.255.255.0 -mapall=root:wheel

