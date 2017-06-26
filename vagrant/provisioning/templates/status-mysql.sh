#!/usr/bin/env bash
##
 # Copyright © 2017 by Matt Johnson. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 ##

set -eux

yum -q list installed {{ mysql_server_package_name }} &>/dev/null && echo true || echo false
