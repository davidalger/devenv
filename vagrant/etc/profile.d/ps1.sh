# configure a pretty ps1

if [[ -f "/etc/.vagranthost" ]]; then
    export PS1='\[\033[0;34m\]\u\[\033[0m\]:\@:\[\033[0;37m\]\w\[\033[0m\]$(
        [[ $(git rev-parse --show-toplevel 2>/dev/null) != "/Volumes/Server" ]] && printf " $(
            git status -sb 2>/dev/null | grep -v "## " | head -n 1 | wc -l | tr 01 " *" | tr -d "[:blank:]";
            git status -sb 2>/dev/null | grep "## " | tr -d "#[:blank:]" | cut -d "." -f1;
        ) " | tr -d "\n" | grep -v "  "
    )$ '
else
    export PS1='\[\033[0;36m\]\u@\h\[\033[0m\]:\@:\[\033[0;37m\]\w\[\033[0m\]$ '
fi
