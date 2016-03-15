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

confdir=/etc/httpd/sites.d
sslconfdir=/etc/nginx/sites.d
vhosttemplate=$confdir/__vhost.conf.template
ssltemplate=$sslconfdir/__vhost-ssl.conf.template
confcust=.vhost.conf
sslconfcust=.ssl.conf
sitesdir=/server/sites
ssldir=/server/.shared/ssl
opensslconfig=/server/vagrant/etc/openssl

function generate_ssl_cert {
    host="$1"
    SAN="DNS.1:*.$host,DNS.2:$host" openssl req -new -sha256 -key $ssldir/local.key.pem -out $ssldir/$host.csr.pem \
        -config $opensslconfig/vhost.conf \
        -subj "/C=US/CN=$host"

    yes | openssl ca -config $opensslconfig/rootca.conf \
        -extensions server_cert -days 375 -notext -md sha256 \
        -in $ssldir/$host.csr.pem \
        -out $ssldir/$host.crt.pem
}

if [[ "$1" == "--reset" ]]; then
    echo "==> scrubbing all open pubs"
    rm -vf $confdir/*.conf | sed "s#$confdir/#    closed #g" | cut -d . -f1
    rm -vf $sslconfdir/*.conf | sed "s#$sslconfdir/#    closed ssl config #g" | cut -d . -f1
    rm -vf $ssldir/*.c??.pem | sed "s#$ssldir/#    removed ssl cert file #g" | cut -d . -f1
fi

echo "==> scouting for new pubs"

# apache detection loop
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

            cp "$vhosttemplate" "$conffile"
            perl -pi -e "s/__HOSTNAME__/$hostname/g" "$conffile"
            perl -pi -e "s/__PUBNAME__/$pubname/g" "$conffile"

            echo "    opened $hostname"
            break
        fi
    done
done

# ngnix ssl detection loop
for site in $(find $sitesdir -maxdepth 1 -type d); do
    hostname="$(basename $site)"
    sslconffile="$sslconfdir/$hostname.conf"

    # custom ssl config
    if [[ -f "$site/$sslconfcust" ]]; then
        # if the file exists and is identical, don't bother replacing it
        if [[ -f "$sslconffile" ]] && cmp "$sslconffile" "$site/$sslconfcust" > /dev/null; then
            continue
        fi

        if [[ -f "$sslconffile" ]]; then
            echo "    configured $hostname for ssl (custom vhost was updated)"
        else
            echo "    configured $hostname for ssl (custom vhost)"
        fi

        cp "$site/$sslconfcust" "$sslconffile"
        continue
    fi

    for try in $(echo "pub html htdocs"); do
        pubdir="${site}/${try}"
        if [[ -d "$pubdir" ]]; then
            pubname=$(basename $pubdir)

            if [[ -f "$sslconffile" ]]; then
                break
            fi

            cp "$ssltemplate" "$sslconffile"
            perl -pi -e "s/__HOSTNAME__/$hostname/g" "$sslconffile"
            perl -pi -e "s/__PUBNAME__/$pubname/g" "$sslconffile"

            generate_ssl_cert "$hostname" 2> /dev/null

            echo "    configured $hostname for ssl"
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
        rm -f "$sslconfdir/$confname.conf"
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
echo "==> reloading nginx"
if [[ -x "$(which vagrant 2> /dev/null)" ]]; then
    vagrant ssh web -- 'sudo service nginx reload'
else
    sudo service nginx reload || true    # mask the LSB exit code (expected to be 4)
fi
echo "==> nginx ready to run"
