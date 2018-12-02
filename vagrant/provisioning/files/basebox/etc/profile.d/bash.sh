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
# bash specific setup

# only run if we are inside a bash shell
if [[ -z $BASH_VERSION ]]; then
    return;
fi

# brew completion if present
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

# git completion
[ -f ~/.git-completion.bash ] && . ~/.git-completion.bash

# command history searching (only bind when we have a tty)
if [ -t 1 ]; then
    bind '"\e[A":history-search-backward'
    bind '"\e[B":history-search-forward'
fi
