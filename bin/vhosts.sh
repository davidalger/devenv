#!/usr/bin/env bash

set -e
confdir=/server/vagrant/etc/httpd/sites.d
template=$confdir/__vhost.conf.template
sitesdir=/server/sites

echo "==> scouting pubs in $sitesdir/"
for site in $(ls -1d $sitesdir/*/); do
    if [[ "$(basename $site)" == "00_localhost" ]]; then
        continue
    fi
    for try in $(echo "pub html htdocs"); do
        pubdir="${site}${try}"
        if [[ -d "$pubdir" ]]; then
            hostname=$(basename $(dirname $pubdir))
            pubname=$(basename $pubdir)
            conffile="$confdir/$hostname.conf"
            
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
