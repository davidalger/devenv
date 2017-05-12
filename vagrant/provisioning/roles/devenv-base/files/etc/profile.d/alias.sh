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
# host specific aliases

if [ -f "/etc/.vagranthost" ]; then
    
    # general shortcuts
    alias st="open -a sourcetree"
    alias togglehidden='SET="com.apple.finder AppleShowAllFiles"; VAL=YES && [ "$(defaults read $SET)" == "YES" ] && VAL=NO; defaults write $SET $VAL; killall Finder'
    
    if [ -x /System/Library/CoreServices/Applications/Network\ Utility.app/Contents/Resources/stroke ]; then
        alias stroke="/System/Library/CoreServices/Applications/Network\ Utility.app/Contents/Resources/stroke"
    fi
    if [ -x "$(which dtrace)" ]; then
        alias iotrace="sudo dtrace -n 'syscall::open*:entry { printf(\"%s %s\",execname,copyinstr(arg0)); }'"
    fi

fi

########################################
# vm specific aliases
# if [ ! -f "/etc/.vagranthost" ]; then
    # vm specific aliases should be added here
# fi

########################################
# generic aliases

# generic shortcuts
alias php-debug="php -d xdebug.remote_autostart=on"
alias trail="tail -f"

# file manipulation
alias crlf-to-lf="find ./ -type f | grep -vE '.svn/|.git/' | xargs -n1 perl -p -i -e 's/\r\n/\n/g'"
alias rsyncf="rsync --exclude-from ~/.rsync_excludes"
alias udiff="diff -urB \$1 \$2 | grep -v 'Only in' | grep -v 'diff ' | sed -E 's#(---|\+\+\+) /.*/htdocs/(.*)#\1 \2#g'"
alias mdiff="diff -Bbwr -I ' \*.*'"

# magento shortcuts
alias mreports='grep -rE ^a: var/report/ | cut -d '\''#'\'' -f 1 | cut -d '\'';'\'' -f 2 | sort | uniq -c | sort -n'
alias mexceptions='ack "^Exception" "$1" | sort | uniq -c | sort -nr | vi -c "set nowrap" -'
# alias flush-cache-storage="php -r \"require_once 'app/Mage.php'; umask(0); Mage::app()->getCacheInstance()->flush();\""
# alias flush-cache="php -r \"require_once 'app/Mage.php'; umask(0); Mage::app()->cleanCache();\""
# alias cron-reset="find var/cache/ -type f -name '*CRON*' -print0 | xargs -0 rm"

# setup git aliases if they do not exist
if [ -x "$(which git 2> /dev/null)" ]; then
    if [ "$(git config --global --get alias.permission-reset)" = "" ]; then
        git config --global --add alias.permission-reset \
            '!git diff -p -R | grep -E "^(diff|(old|new) mode)" | git apply'
    fi

    # TODO convert these to git aliases
    alias git-log-pretty='git log --pretty=format:"%h %ad %an %s" --date=short'
    alias git-log-graph='git log --all --decorate --graph --color=always'
    alias git-prune-remote-branches='git branch -r --merged | grep -v develop | grep -v master | grep origin | grep -v "$(git branch | grep \* | cut -d " " -f2)" | grep -v ">" | xargs -L1 | cut -d "/" -f2-5 | xargs git push origin --delete'
    alias git-prune-local-branches='git branch --merged | grep -v develop | grep -v master | grep -v "$(git branch | grep \* | cut -d " " -f2)" | grep -v ">" | xargs -L1 | xargs -n1 git branch -d'
fi

# timestamp for use in file names
alias ts="date +%F_%H-%M-%S"
