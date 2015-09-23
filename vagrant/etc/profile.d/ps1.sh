# configure a pretty ps1

if [[ -f "/etc/.vagranthost" ]]; then
    PS1='\[\033[0;34m\]\u\[\033[0m\]:\@:\[\033[0;37m\]\w\[\033[0m\]'
else
    PS1='\[\033[0;36m\]\u@\h\[\033[0m\]:\@:\[\033[0;37m\]\w\[\033[0m\]'
fi

if [[ -x "$(which git 2> /dev/null)" ]]; then
    GIT_PS1_SHOWDIRTYSTATE=1
    PS1="$PS1"'$(gs=$(__git_ps1) && [ "$gs" ] && echo "$gs ")$ '
else
    PS1="$PS1$ "
fi

export PS1
