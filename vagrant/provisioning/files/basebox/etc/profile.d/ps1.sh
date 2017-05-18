#!/usr/bin/env bash
##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

########################################
# configure a pretty ps1

## don't customize ps1 for non-bash shell
if [[ -z $BASH_VERSION ]]; then
    return;
fi

## set git ps1 options one time so overriding in local profile is possible
if [[ -x "$(which git 2> /dev/null)" ]]; then
    GIT_PS1_SHOWDIRTYSTATE=1
fi

## custom __git_ps1 to add padding and prevent display when in server env repo
function __git_ps1_devenv {
    if [[ ! -x "$(which git 2> /dev/null)" ]]; then
        return
    fi
    
    server_path="$(readlink /server || echo /server)"
    if [[ "$(git rev-parse --show-toplevel 2>/dev/null | grep -vE "^$server_path$")" ]]; then
        gs=$(__git_ps1) && [ "$gs" ] && echo "$gs "
    fi
}

## set PS1 with different colors / options on host vs guest machines
if [[ -f "/etc/.vagranthost" ]]; then
    export PS1='\[\033[0;34m\]\u\[\033[0m\]:\@:\[\033[0;37m\]\w\[\033[0m\]$(__git_ps1_devenv)$ '
else
    if [[ $EUID -ne 0 ]]; then
        export PS1='\[\033[0;36m\]\u@\h\[\033[0m\]:\@:\[\033[0;37m\]\w\[\033[0m\]$ '
    else
        export PS1='\[\033[0;5m\]\u@\h\[\033[0m\]:\@:\[\033[0;31m\]\w\[\033[0m\]# '
    fi
fi
