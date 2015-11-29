#!/usr/bin/env bash
##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

set -e

confdir=/server/vagrant/etc/httpd/sites.d
sslconfdir=/etc/nginx/conf.d/sites.d
vhosttemplate=$confdir/__vhost.conf.template
ssltemplate=/server/vagrant/etc/nginx/sites.d/__vhost-ssl.conf.template
confcust=.vhost.conf
sitesdir=/server/sites
ssldir=/server/.shared/ssl

function generate_ssl_cert {
    host=$1
    openssl req -new -sha256 -key $ssldir/local.key.pem -out $ssldir/$host.csr.pem \
        -subj "/C=US/CN=$host"

    yes | openssl ca -config /server/vagrant/etc/openssl/openssl.conf \
        -extensions server_cert -days 375 -notext -md sha256 \
        -in $ssldir/$host.csr.pem \
        -out $ssldir/$host.crt.pem
}

if [[ "$1" == "--reset" ]]; then
    echo "==> scrubbing all open pubs"
    rm -vf $confdir/*.conf | sed "s#$confdir/#    closed #g" | cut -d . -f1
fi

echo "==> scouting for new pubs"
for site in $(find $sitesdir -maxdepth 1 -type d); do
    hostname="$(basename $site)"
    conffile="$confdir/$hostname.conf"
    sslconffile="$sslconfdir/$hostname.conf"
    
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

            # generate apache vhost files
            cp "$vhosttemplate" "$conffile"
            perl -pi -e "s/__HOSTNAME__/$hostname/g" "$conffile"
            perl -pi -e "s/__PUBNAME__/$pubname/g" "$conffile"

            # generate nginx ssl vhost files
            cp "$ssltemplate" "$sslconffile"
            perl -pi -e "s/__HOSTNAME__/$hostname/g" "$sslconffile"
            perl -pi -e "s/__PUBNAME__/$pubname/g" "$sslconffile"

            generate_ssl_cert $hostname

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
        rm -f "$sslconfdir/$confname"
        echo "    closed $confname"
    fi
done
echo "==> all old pubs closed"
echo "==> reloading apache"
if [[ -x "$(which vagrant 2> /dev/null)" ]]; then
    vagrant ssh web -- 'sudo service httpd reload'
else
    sudo service httpd reload || true    # mask the LSB exit code (expected to be 4)
fi
echo "==> apache ready to run"
