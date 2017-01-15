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

# determine which version of php we are installing and determine which extra RPMs are needed
case "$PHP_VERSION" in
    
    "" ) # set default of PHP 7.0 if none was specified
        PHP_VERSION="70"
        ;&  ## fallthrough to below case, we know it matches
    55 | 56 | 70 )
        extra_repos="--enablerepo=remi --enablerepo=remi-php${PHP_VERSION}"
        ;;
    54 )
        extra_repos="--enablerepo=remi"
        >&2 echo "Warning: PHP 5.4 is deprecated"
        ;;
    * )
        >&2 echo "Error: Invalid or unsupported PHP version '$PHP_VERSION' specified"
        exit -1;
esac

export PHP_VERSION extra_repos
