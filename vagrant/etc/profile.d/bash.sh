#!/usr/bin/env bash

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
