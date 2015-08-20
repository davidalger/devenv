# Development Environment

## Host Setup
* Add the following line to /etc/exports and restart nfsd by running `sudo nfsd restart`

        "/Volumes/Server/" -alldirs -network 10.19.89.0 -mask 255.255.255.0 -mapall=0:0

