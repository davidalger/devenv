# set environemnt variables

# set magento developer mode env vars
export MAGE_IS_DEVELOPER_MODE=1
export MAGE_MODE=developer

# set vagrant environemnt vars
export VAGRANT_IS_SETUP=true
export VAGRANT_HOME=/server/.vagrant/home
export VAGRANT_DOTFILE_PATH=.vagrant/state
export VAGRANT_LOG=

# set central composer home
export COMPOSER_HOME=/server/.shared/composer

# configure PATH to use local and user scripts
export PATH=~/bin:/usr/local/bin:$PATH:/usr/local/sbin

# use textmate as editor if mate cli tool is present
[ -x /usr/local/bin/mate ] && export EDITOR="/usr/local/bin/mate -w"

# textmate support path if present
if [ -d "/Applications/TextMate.app/Contents/SharedSupport/Support" ]; then
    export TM_SUPPORT_PATH='/Applications/TextMate.app/Contents/SharedSupport/Support'
fi

# brew completion if present
if [ -x "$(which brew 2> /dev/null)" ] && [ -f $(brew --prefix)/etc/bash_completion ]; then
  . $(brew --prefix)/etc/bash_completion
fi

# git completion
[ -f ~/.git-completion.bash ] && . ~/.git-completion.bash

# setup rvm if present
[ -s "$HOME/.rvm/scripts/rvm" ] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

# bash specific env
bind '"\e[A":history-search-backward'
bind '"\e[B":history-search-forward'
