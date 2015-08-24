#!/usr/bin/env bash

set -e

confdir=/server/vagrant/etc/httpd/sites.d
template=$confdir/__vhost.conf.template
confcust=.vhost.conf
sitesdir=/server/sites

echo "==> scouting pubs in $sitesdir/"
for site in $(find $sitesdir -type d -maxdepth 1); do
    hostname="$(basename $site)"
    conffile="$confdir/$hostname.conf"
    
    if [[ "$hostname" == "00_localhost" ]]; then
        continue
    fi
    
    if [[ -f "$site/$confcust" ]]; then
        # if the file exists and is identical, don't bother replacing it
        if [[ -f "$conffile" ]] && cmp "$conffile" "$site/$confcust" > /dev/null; then
            continue
        fi
        
        if [[ -f "$conffile" ]]; then
            echo "    added: $hostname (custom vhost was updated)"
        else
            echo "    added: $hostname (custom vhost)"
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

            echo "    added: $hostname"
            break
        fi
    done
done
echo "==> found all local pubs"

echo "==> policing old pubs"
for conffile in $(ls -1 $confdir/*.conf); do
    confname="$(echo "$(basename "$conffile")" | sed 's/\.conf$//')"
    if [[ "$confname" == "00_localhost" ]]; then
        continue
    fi
    if [[ ! -d "$sitesdir/$confname" ]]; then
        rm -f "$conffile"
        echo "closed: $confname"
    fi
done
echo "==> all old pubs closed"
echo "==> reloading apache"
vagrant ssh web -- "sudo service httpd reload"
echo "==> apache ready to run"
