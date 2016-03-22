#!/usr/bin/env bash
##
 # Copyright © 2016 by David Alger. All rights reserved
 #
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 #
 # http://davidalger.com/contact/
 ##

set -eu

########################################
# Init default script vars

sites_dir=/server/sites
certs_dir=/server/.shared/ssl
is_quiet=
no_reload=
reset_config=
reset_certs=

########################################
# re-execute with root priviledges
if [[ "$(id -u)" != 0 ]]; then
    sudo $0 "$@"
    exit
fi

########################################
# parse any arguments passed in
for arg in "$@"; do
    case $arg in
        -q|--quiet)
            is_quiet=1
            ;;
        --no-reload)
            no_reload=1
            ;;
        --reset-config)
            reset_config=1
            ;;
        --reset-certs)
            reset_certs=1
            ;;
        -h|--help)
            echo "Usage: $(basename $0) [-h|--help] [-q|--quiet] [--no-reload] [--reset-config] [--reset-certs]"
            exit -1
            ;;
        *)
            >&2 echo "Error: Unrecognized argument $arg"
            exit -1
            ;;
    esac
done

########################################
# Define all our routines

function msg {
    [[ "$1" = "-n" ]] && output="${@:2}" || output="$@\n"
    [[ -z $is_quiet ]] && printf "$output" || true
}

function generate_cert {
    hostname="$1"

    if [[ -f $certs_dir/$hostname.crt.pem ]]; then
        return
    fi
    msg "   + signing cert $hostname.crt.pem"

    SAN="DNS.1:*.$hostname,DNS.2:$hostname" openssl req -new -sha256 \
        -key $certs_dir/local.key.pem \
        -out $certs_dir/$hostname.csr.pem \
        -config /etc/openssl/vhost.conf \
        -subj "/C=US/CN=$hostname"

    yes | openssl ca -config /etc/openssl/rootca.conf -extensions server_cert -days 375 -notext -md sha256 \
        -in $certs_dir/$hostname.csr.pem \
        -out $certs_dir/$hostname.crt.pem
}

function generate_config {
    service="$1"
    site_name="$2"
    site_hosts="$3"
    site_path="$4"

    conf_dir="/etc/$service/sites.d"
    conf_file="$conf_dir/$site_name.conf"
    conf_src=

    template="$conf_dir/__vhost.conf.template"
    override="$site_path/.$service.conf"
    status=
    
    site_pub=$(ls -1dU "$site_path"/{pub,html,htdocs} 2>/dev/null | head -n1)
    [[ -n $site_pub ]] && site_pub=$(basename "$site_pub") || site_pub=pub

    # figure out what to src the config from
    if [[ -f "$override" ]]; then
        # if override has not been copied or is different, we process it
        if [[ ! -f "$conf_file" ]] || ! cmp "$override" "$conf_file" > /dev/null; then
            status="(override)"
            [[ -f "$conf_file" ]] && status="$status (updated)"
            
            # if pub dir does not exist, override verbatim without var replacement
            if [[ ! -d "$site_path/$site_pub" ]]; then
                msg "   + $service config $status"
                cp "$override" "$conf_file"
                return
            fi
            
            # failing above check, use as template in below loop
            conf_src="$override"
        fi
    elif [[ -d "$site_path/$site_pub" ]]; then
        conf_src="$template"
    fi

    # if we have something to copy and there is nothing there already, copy and replace in vars
    if [[ -n "$conf_src" ]] && [[ ! -f "$conf_file" ]]; then
        
        # loop over list of hostnames and append template for each one
        for hostname in $site_hosts; do
            msg "   + $service config for $hostname $status"
            cat "$conf_src" >> "$conf_file"

            perl -pi -e "s/__SITE_NAME__/$site_name/g" "$conf_file"
            perl -pi -e "s/__SITE_HOST__/$hostname/g" "$conf_file"
            perl -pi -e "s/__SITE_PUB__/$site_pub/g" "$conf_file"
        done
    fi
}

function process_site {
    site_name="$1"
    site_path="$2"
    site_hosts[0]=

    # parse in list of custom hostnames if present
    if [[ -f $site_path/.hostnames ]] && [[ "$(wc -l $site_path/.hostnames | cut -d ' ' -f1)" != 0 ]]; then
        readarray -t site_hosts < $site_path/.hostnames
    fi
    [[ -z ${site_hosts[@]} ]] && site_hosts=("$(basename $site_path)")      # default hostname is site name

    # clear hostnames which do not contain a period
    for (( i = 0, l = ${#site_hosts[@]}; i < l; i++ )); do
        [[ ${site_hosts[i]} != *"."* ]] && site_hosts[i]=
    done

    # if no hostnames are remaining, return to caller
    [[ -z ${site_hosts[@]} ]] && return

    # generate secure certificate for each hostname
    for hostname in ${site_hosts[@]}; do
        generate_cert $hostname 2> /dev/null
    done

    # call configuration generators for each service
    generate_config httpd $site_name "${site_hosts[@]}" $site_path
    generate_config nginx $site_name "${site_hosts[@]}" $site_path
}

function remove_files {
    [[ $is_quiet ]] && verbosity= || verbosity=" -v "
    rm $verbosity -f "$@" | sed -e "s#^[^/]*/# - /#g" | cut -d \' -f1
}

function main {
    [[ $is_quiet ]] && stdout=/dev/null || stdout=/dev/stdout

    if [[ -f /etc/.vagranthost ]]; then
        >&2 echo "Error: This script should be run from within the vagrant machine. Please vagrant ssh, then retry"
        exit 1
    fi

    msg "==> Removing pre-existing configuration"
    [[ $reset_config ]] && remove_files /etc/{httpd,nginx}/sites.d/*.conf
    [[ $reset_certs ]] && remove_files $certs_dir/*.c??.pem

    sites_list=$(find $sites_dir -mindepth 1 -maxdepth 1 -type d)

    msg "==> Generating site configuration"
    for site_path in $sites_list; do
        site_name="$(basename $site_path)"
        
        site_msg=$(process_site $site_name $site_path)
        [[ -n $site_msg ]] && msg " + $site_name\n$site_msg"    # only list if process_site emitted output
    done

    if [[ ! $no_reload ]]; then
        msg -n "==> " && service httpd reload > $stdout || true    # mask the LSB exit code (expected to be 4)
        msg -n "==> " && service nginx reload > $stdout || true    # mask the LSB exit code (expected to be 4)
    fi

}; main "$@"
