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
if [ -x "$(which brew 2> /dev/null)" ] && [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

# git completion
[ -f ~/.git-completion.bash ] && . ~/.git-completion.bash

# command history searching
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'
