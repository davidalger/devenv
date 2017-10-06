#!/usr/bin/env bash
##
 # Copyright © 2016 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

set -e

SSL_DIR="{{ shared_ssl_dir }}"

if ! [[ -d $SSL_DIR/rootca/ ]]; then
    mkdir -p $SSL_DIR/rootca/{certs,crl,newcerts,private}

    touch $SSL_DIR/rootca/index.txt
    echo 1000 > $SSL_DIR/rootca/serial
fi

# create a CA root certificate if none present
if [[ ! -f $SSL_DIR/rootca/private/ca.key.pem ]]; then
    openssl genrsa -out $SSL_DIR/rootca/private/ca.key.pem 4096

    openssl req -config /etc/openssl/rootca.conf -new -x509 -days 7300 -sha256 -extensions v3_ca \
        -key $SSL_DIR/rootca/private/ca.key.pem \
        -out $SSL_DIR/rootca/certs/ca.cert.pem \
        -subj "/C=US/O=Vagrant DevEnv"

    # alert user where to find root ca cert and what to do with it
    >&2 echo "Note: You must add $SSL_DIR/rootca/certs/ca.cert.pem to trusted certs on host."
fi

# add local CA root to the trusted key-store and enable Shared System Certificates
cp $SSL_DIR/rootca/certs/ca.cert.pem /etc/pki/ca-trust/source/anchors/local-ca.key.pem

update-ca-trust
update-ca-trust enable

# create local ssl private key
[[ ! -d /etc/nginx/ssl ]] && mkdir -p /etc/nginx/ssl
if [[ ! -f /etc/nginx/ssl/local.key.pem ]]; then
    openssl genrsa -out /etc/nginx/ssl/local.key.pem 2048
fi
