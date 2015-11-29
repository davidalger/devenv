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

ssldir=/server/.shared/ssl
configpath=/server/vagrant/etc/openssl/rootca.conf

########################################
# configure ssl shared dir

if ! [[ -d $ssldir ]]; then
    mkdir -p $ssldir/rootca

    mkdir $ssldir/rootca/certs
    mkdir $ssldir/rootca/crl
    mkdir $ssldir/rootca/newcerts
    mkdir $ssldir/rootca/private

    touch $ssldir/rootca/index.txt
    echo 1000 > $ssldir/rootca/serial
fi

########################################
# configure ssl root CA

if [[ -f $ssldir/rootca/private/ca.key.pem ]]; then
    echo "==> Existing root CA found"
else
    echo "==> Creating root CA"

    openssl genrsa -out $ssldir/rootca/private/ca.key.pem 4096

    openssl req -config $configpath -new -x509 -days 7300 -sha256 -extensions v3_ca \
        -key $ssldir/rootca/private/ca.key.pem \
        -out $ssldir/rootca/certs/ca.cert.pem \
        -subj "/C=US/O=Classy Llama Dev"

    echo "==> Root CA created."

    # alert user where to find root ca cert and what to do with it
    >&2 echo "NOTE: you must add $ssldir/rootca/certs/ca.cert.pem to trusted certs on host."
fi

########################################
# configure local ssl private key

if [[ -f $ssldir/local.key.pem ]]; then
    echo "==> Existing local ssl private key found"
else
    echo "==> Creating local SSL private key"

    openssl genrsa -out $ssldir/local.key.pem 2048

    echo "==> Local SSL private key created"
fi
