#!/usr/bin/env bash

set -e

confdir=/server/vagrant/etc/httpd/sites.d
template=$confdir/__vhost.conf.template
confcust=.vhost.conf
sitesdir=/server/sites

if [[ "$1" == "--reset" ]]; then
    echo "==> scrubbing all open pubs"
    rm -vf $confdir/*.conf | sed "s#$confdir/#    closed #g" | cut -d . -f1
fi

echo "==> scouting for new pubs"
for site in $(find $sitesdir -maxdepth 1 -type d); do
    hostname="$(basename $site)"
    conffile="$confdir/$hostname.conf"
    
    if [[ -f "$site/$confcust" ]]; then
        # if the file exists and is identical, don't bother replacing it
        if [[ -f "$conffile" ]] && cmp "$conffile" "$site/$confcust" > /dev/null; then
            continue
        fi
        
        if [[ -f "$conffile" ]]; then
            echo "    opened $hostname (custom vhost was updated)"
        else
            echo "    opened $hostname (custom vhost)"
        fi
        
        cp "$site/$confcust" "$conffile"
        continue
    fi
    
    for try in $(echo "pub html htdocs"); do
        pubdir="${site}/${try}"
        if [[ -d "$pubdir" ]]; then
            pubname=$(basename $pubdir)
            
            if [[ -f "$conffile" ]]; then
                break
            fi
            
            cp "$template" "$conffile"
            perl -pi -e "s/__HOSTNAME__/$hostname/g" "$conffile"
            perl -pi -e "s/__PUBNAME__/$pubname/g" "$conffile"

            echo "    opened $hostname"
            break
        fi
    done
done
echo "==> found all local pubs"

echo "==> policing old pubs"
for conffile in $(ls -1 $confdir/*.conf); do
    confname="$(echo "$(basename "$conffile")" | sed 's/\.conf$//')"
    if [[ "$confname" == "__localhost" ]]; then
        continue
    fi
    if [[ ! -d "$sitesdir/$confname" ]]; then
        rm -f "$conffile"
        echo "    closed $confname"
    fi
done
echo "==> all old pubs closed"
echo "==> reloading apache"
if [[ -x "$(which vagrant 2> /dev/null)" ]]; then
    vagrant ssh web -- 'sudo service httpd reload'
else
    service httpd reload || true    # mask the LSB exit code (expected to be 4)
fi
echo "==> apache ready to run"
