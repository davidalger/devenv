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

sitesdir=/server/sites
siteroots="pub html htdocs"
hostcust=.hostnames

apacheconfdir=/server/vagrant/etc/httpd/sites.d
apachetemplate=$apacheconfdir/__apache.conf.template
apachecust=.apache.conf
allcusthostarray=

nginxconfdir=/server/vagrant/etc/nginx/sites.d
nginxtemplate=$nginxconfdir/__nginx.conf.template
nginxcust=.nginx.conf

varnishconfdir=/server/vagrant/etc/varnish/sites.d
varnishtemplate=$varnishconfdir/__varnish.vcl.template
varnishcust=.varnish.vcl

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
    echo "==> scrubbing all open sites"
    rm -vf $apacheconfdir/*.conf | sed "s#$apacheconfdir/#    closed apache config #g" | cut -d . -f1
    rm -vf $nginxconfdir/*.conf | sed "s#$nginxconfdir/#    closed nginx config #g" | cut -d . -f1
    rm -vf $varnishconfdir/*.vcl | sed "s#$varnishconfdir/#    closed varnish config #g" | cut -d . -f1
    rm -vf $ssldir/*.c??.pem | sed "s#$ssldir/#    removed ssl cert file #g" | cut -d . -f1
fi

echo "==> scouting for new sites"

# site detection loop
for site in $(find $sitesdir -maxdepth 1 -type d); do

    # skip the sites dir ./
    if [[ "$site" == "$sitesdir" ]]; then
        continue
    fi

    sitedir="$(basename $site)"

    # determine site root
    siteroot=
    for try in $(echo "pub html htdocs"); do
        siterootdir="${site}/${try}"
        if [[ -d "$siterootdir" ]]; then
            siteroot=$(basename $siterootdir)
            break
        fi
    done

    # use custom list of hostnames or the directory name as a hostname
    hostnamearray=()
    if [[ -f "$site/$hostcust" ]]; then
        readarray -t hostnamearray < "$site/$hostcust"
        allcusthostarray=( ${allcusthostarray[@]} ${hostnamearray[@]} )
    else
        hostnamearray+=("$(basename $site)")
    fi

    # loop through array of hostnames for this site directory
    hostname=
    for hostname in "${hostnamearray[@]}"; do
        # skip any hostnames that are empty - like from empty lines in custom hostname files
        if [[ "$hostname" == "" ]]; then
            continue
        fi

        # apache use custom config or build using template
        if [[ -f "$site/$apachecust" ]]; then
            apachecustconffile="$apacheconfdir/$sitedir.conf"
            # if the file doesn't exists or is not identical, replace it
            if [[ ! -f "$apachecustconffile" ]] || ! cmp "$apachecustconffile" "$site/$apachecust" > /dev/null; then
                if [[ -f "$apachecustconffile" ]]; then
                    echo "    opened $hostname for apache (custom config was updated)"
                else
                    echo "    opened $hostname for apache (custom config)"
                fi

                cp "$site/$apachecust" "$apachecustconffile"
            fi
        else
            apacheconffile="$apacheconfdir/$hostname.conf"
            # if there is a site root and the config file doesn't already exist create one from the template
            if [[ ! -z "$siteroot" ]] && [[ ! -f "$apacheconffile" ]]; then
                cp "$apachetemplate" "$apacheconffile"
                perl -pi -e "s/__HOSTNAME__/$hostname/g" "$apacheconffile"
                perl -pi -e "s/__SITEDIR__/$sitedir/g" "$apacheconffile"
                perl -pi -e "s/__SITEROOT__/$siteroot/g" "$apacheconffile"

                echo "    opened $hostname for apache"
            fi
        fi

        # nginx use custom config or build using template
        if [[ -f "$site/$nginxcust" ]]; then
            nginxcustconffile="$nginxconfdir/$sitedir.conf"
            # if the file doesn't exists or is not identical, replace it
            if [[ ! -f "$nginxcustconffile" ]] || ! cmp "$nginxcustconffile" "$site/$nginxcust" > /dev/null; then
                if [[ -f "$nginxcustconffile" ]]; then
                    echo "    opened $hostname for nginx (custom config was updated)"
                else
                    echo "    opened $hostname for nginx (custom config)"
                fi

                cp "$site/$nginxcust" "$nginxcustconffile"
            fi
        else
            nginxconffile="$nginxconfdir/$hostname.conf"
            # if there is a site root and the config file doesn't already exist create one from the template
            if [[ ! -z "$siteroot" ]] && [[ ! -f "$nginxconffile" ]]; then
                cp "$nginxtemplate" "$nginxconffile"
                perl -pi -e "s/__HOSTNAME__/$hostname/g" "$nginxconffile"
                    perl -pi -e "s/__SITEDIR__/$sitedir/g" "$nginxconffile"
                    perl -pi -e "s/__SITEROOT__/$siteroot/g" "$nginxconffile"

                echo "    opened $hostname for nginx"
            fi
        fi

        # varnish use custom config or build using template
        if [[ -f "$site/$varnishcust" ]]; then
            varnishcustconffile="$varnishconfdir/$sitedir.vcl"
            # if the file doesn't exists or is not identical, replace it
            if [[ ! -f "$varnishcustconffile" ]] || ! cmp "$varnishcustconffile" "$site/$varnishcust" > /dev/null; then
                if [[ -f "$varnishcustconffile" ]]; then
                    echo "    opened $hostname for varnish (custom config was updated)"
                else
                    echo "    opened $hostname for varnish (custom config)"
                fi

                cp "$site/$varnishcust" "$varnishcustconffile"
            fi
        else
            varnishconffile="$varnishconfdir/$hostname.vcl"
            # if there is a site root and the config file doesn't already exist create one from the template
            if [[ ! -z "$siteroot" ]] && [[ ! -f "$varnishconffile" ]]; then
                cp "$varnishtemplate" "$varnishconffile"
                perl -pi -e "s/__HOSTNAME__/$hostname/g" "$varnishconffile"
                perl -pi -e "s/__PUBNAME__/$siteroot/g" "$varnishconffile"

                echo "    opened $hostname for varnish"
            fi
        fi

        # ssl certificates
        if [[ ! -z "$siteroot" ]]; then
            # if either certificate file are not already there, generate the ssl certificates
            if [[ ! -f "$ssldir/$hostname.csr.pem" ]] || [[ ! -f "$ssldir/$hostname.crt.pem" ]]; then
                echo "    generated $hostname ssl cert"
                generate_ssl_cert "$hostname" 2> /dev/null
            fi
        fi
    done
done
echo "==> found all local sites"

echo "==> policing old sites"
for apacheconffile in $(ls -1 $apacheconfdir/*.conf); do
    confname="$(echo "$(basename "$apacheconffile")" | sed 's/\.conf$//')"
    if [[ "$confname" == "__localhost" ]]; then
        continue
    fi

    # skip any config files for custom hostnames
    if [[ ${allcusthostarray[*]} =~ "$confname" ]]; then
        continue
    fi

    # purge old files if the directory doesn't exist anymore
    if [[ ! -d "$sitesdir/$confname" ]]; then
        rm -f "$apacheconffile"
        rm -f "$nginxconfdir/$confname.conf"
        rm -f "$varnishconfdir/$confname.vcl"
        echo "    closed apache $confname"
    fi
done
for nginxconffile in $(ls -1 $nginxconfdir/*.conf); do
    confname="$(echo "$(basename "$nginxconffile")" | sed 's/\.conf$//')"
    if [[ "$confname" == "__localhost" ]]; then
        continue
    fi

    # skip any config files for custom hostnames
    if [[ ${allcusthostarray[*]} =~ "$confname" ]]; then
        continue
    fi

    # purge old files if the directory doesn't exist anymore
    if [[ ! -d "$sitesdir/$confname" ]]; then
        rm -f "$nginxconffile"
        echo "    closed nginx $confname"
    fi
done
for varnishconffile in $(ls -1 $varnishconfdir/*.vcl); do
    confname="$(echo "$(basename "$varnishconffile")" | sed 's/\.vcl//')"
    if [[ "$confname" == "__localhost" ]]; then
        continue
    fi

    # skip any config files for custom hostnames
    if [[ ${allcusthostarray[*]} =~ "$confname" ]]; then
        continue
    fi

    # purge old files if the directory doesn't exist anymore
    if [[ ! -d "$sitesdir/$confname" ]]; then
        rm -f "$varnishconffile"
        echo "    closed varnish $confname"
    fi
done
echo "==> all old sites closed"

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

# TODO: consider trying to reload varnish to preserve cache
echo "==> restarting varnish"
if [[ -x "$(which vagrant 2> /dev/null)" ]]; then
    vagrant ssh web -- 'sudo service varnish restart'
else
    sudo service varnish restart || true    # mask the LSB exit code (expected to be 4)
fi
echo "==> varnish ready to run"