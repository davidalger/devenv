#!/usr/bin/env bash
set -e

made_changes=
echo "==> Checking dependencies"

##############################
# declare internal functions

function assert_pack {
    echo "==> Checking pack $1"
    
    if ! brew list "$1" > /dev/null 2>&1; then
        echo "==> Installing brew $1"
        brew install "$1" > /dev/null

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

##############################
# install major tooling

# install developer tools if not present
echo "==> Checking command line tools"
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
echo "==> Checking brew package manager"
if ! which brew > /dev/null; then
    echo "==> Installing brew package manager"
    curl -s https://raw.githubusercontent.com/Homebrew/install/master/install | ruby > /dev/null 2>&1
    brew doctor

    made_changes=1
fi

##############################
# install dependencies

sudo mkdir -p /usr/local/bin
if [[ "$(stat -f "%u" /usr/local/bin/)" != "$(id -u)" ]]; then
    sudo chown $(whoami):admin /usr/local/bin
fi

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

# composer has no brew package
echo "==> Checking for composer"
if [[ ! -x /usr/local/bin/composer ]]; then
    echo "==> Installing composer"
    mkdir -p /server/.shared/composer
    wget -q https://getcomposer.org/composer.phar -O /usr/local/bin/composer
    chmod +x /usr/local/bin/composer
fi

##############################
# verify server link and mount

echo "==> Checking /server for environment setup"

if [[ ! -d /server ]] && [[ -L /server ]]; then
    >&2 echo "Warning: /server is a dead symbolic link pointing to nowhere. Removing and moving on..."
    sudo rm -f /server
    made_changes=1
fi

# nothing is at /server, so begin setup by creating it
if [[ ! -d /server ]] && [[ ! -L /server ]]; then
    if [[ -d "/Volumes/Server" ]]; then
        sudo ln -s /Volumes/Server /server
        made_changes=1
    else
        >&2 echo "Warning: Failed to detect /Volumes/Server mount. Creating directory at /server instead"
        sudo mkdir /server
        made_changes=1
    fi
fi

if [[ -d /server ]] && [[ ! -L /server ]]; then
    >&2 echo "Warning: /server is a directory. This may cause case-insensitivity issues in virtual machines."
fi

# verify /server is empty before we start
if [[ ! "$(ls -A /server | head -n1)" ]]; then
    echo "==> Installing devenv at /server"
    sudo chown $(whoami):admin /server
    cd /server
    git init -q
    git remote add origin https://github.com/davidalger/devenv.git
    git fetch -q origin
    git checkout -q master
    vagrant status
    echo "==> Please run `source /etc/profile` in your shell before starting vagrant"

    made_changes=1
elif [[ ! -f /server/vagrant/vagrant.rb ]]; then
    >&2 echo "Error: /server is not empty, but does not appear to be setup either. Moving on..."
fi

##############################
# inform user and exit
if [ $made_changes ]; then
    echo "Process Complete!"
else
    echo "Nothing to do!"
fi
