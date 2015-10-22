#!/usr/bin/env bash
##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

set -e

function setup_devbox {
    made_changes=
    echo "==> Checking dependencies"

    install_environment
    
    assert_pack aescrypt
    assert_pack ansible
    assert_pack autoconf
    assert_pack automake
    assert_pack figlet
    assert_pack git-flow
    assert_pack glib
    assert_pack homebrew/completions/grunt-completion
    assert_pack homebrew/dupes/less
    assert_pack homebrew/dupes/zlib
    
    # assert_pack homebrew/php/composer
    # assert_pack homebrew/php/php-code-sniffer
    # assert_pack homebrew/php/phpcpd
    # assert_pack homebrew/php/phpmd
    # assert_pack homebrew/php/phpunit
    
    assert_pack hub
    assert_pack md5sha1sum
    assert_pack nmap
    assert_pack node
    assert_pack openssl
    assert_pack pcre
    assert_pack python
    assert_pack readline
    assert_pack rename
    assert_pack siege
    assert_pack sloccount
    assert_pack sqlite
    assert_pack wakeonlan
    assert_pack watch

    assert_cask 1password
    assert_cask alfred
    assert_cask java
    assert_cask clipmenu
    assert_cask dropbox
    assert_cask firefox
    assert_cask google-chrome
    assert_cask imageoptim
    assert_cask livereload
    assert_cask phpstorm
    assert_cask sequel-pro
    assert_cask sizeup
    assert_cask skype
    assert_cask sourcetree
    assert_cask textmate

    # inform user and exit
    if [ $made_changes ]; then
        echo "Process Complete!"
    else
        echo "Nothing to do!"
    fi
}

if ! type -t install_environment && [[ -f $(dirname $0)/install.sh ]]; then
    source $(dirname $0)/install.sh
fi

if type -t install_environment; then
    setup_devbox
else
    echo "usage: curl -s https://raw.githubusercontent.com/davidalger/devenv/master/vagrant/bin/install.sh" \
        " https://raw.githubusercontent.com/davidalger/devenv/master/vagrant/bin/devenv.sh | bash /dev/stdin --lib-mode"
fi
