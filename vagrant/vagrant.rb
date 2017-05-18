##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

require_relative 'lib/config'
require_relative 'lib/mount'
require_relative 'lib/provision'
require_relative 'lib/machine'

# configure environment paths
BASE_DIR = base_dir('/server')
MOUNT_PATH = mount_path(BASE_DIR)
VAGRANT_DIR = BASE_DIR + '/vagrant'
SHARED_DIR = BASE_DIR + '/.shared'
SITES_DIR = '/sites'
SITES_MOUNT = '/var/www/sites'

# auto configure host machine
auto_config_host

# begin the configuration sequence
Vagrant.require_version '>= 1.7.4'
Vagrant.configure(2) do |conf|
  conf.vm.define :web, primary: true do |node|
    configure_basebox node, host: 'dev-web70', ip: '10.19.89.14'

    configure_web node
    configure_percona node

    ansible_play(node, 'solr')
    ansible_play(node, 'elasticsearch')
  end

  conf.vm.define :web56, autostart: false do |node|
    configure_basebox node, host: 'dev-web56', ip: '10.19.89.10'

    configure_web node, php_version: 56
    configure_percona node, data_dir: 'web56'

    ansible_play(node, 'solr')
    ansible_play(node, 'elasticsearch')
  end
end
