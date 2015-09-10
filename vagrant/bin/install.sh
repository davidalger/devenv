#!/usr/bin/env bash
set -e

made_changes=
echo "==> Checking dependencies"

function assert_pack {
    echo "==> Checking pack $1"
    
    if ! brew info caskroom/cask/brew-cask > /dev/null; then
        echo "==> Installing brew cask manager"
        brew install caskroom/cask/brew-cask > /dev/null

        made_changes=1
    fi
}

function assert_cask {
    echo "==> Checking cask $1"
    
    if ! brew cask list "$1" > /dev/null 2>&1 ; then
        echo "==> Installing cask "$1""
        brew cask install "$1" > /dev/null

        made_changes=1
    fi
}

# install developer tools if not present
echo "===> Checking command line tools"
if ! xcode-select -p > /dev/null 2>&1; then
    echo "==> Finding command line tools package"
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    xcode_package=$(softwareupdate -l | grep '* Command Line' | head -n1 | sed -E 's/ +\* //g')
    
    echo "==> Installing $xcode_package"
    softwareupdate -i "$xcode_package" -v
    
    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    made_changes=1
fi

# install brew if not present
echo "===> Checking brew package manager"
if ! which brew > /dev/null; then
    echo "==> Installing brew package manager"
    curl -s https://raw.githubusercontent.com/Homebrew/install/master/install | ruby > /dev/null
    brew doctor

    made_changes=1
fi

##############################
# install dependencies

# general tooling
assert_pack ack
assert_pack bash-completion
assert_pack git
assert_pack mysql
assert_pack pv
assert_pack redis
assert_pack ruby
assert_pack tree
assert_pack wget

# virtualization tech
assert_pack caskroom/cask/brew-cask
assert_cask vagrant
assert_pack homebrew/completions/vagrant-completion
assert_cask virtualbox

# inform user
if [ $made_changes ]; then
    echo "Process Complete!"
else
    echo "Nothing to do!"
fi
