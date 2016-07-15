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
  
  configure_common conf
  
  conf.vm.define :db do |node|
    configure_db_vm node, host: 'dev-db', ip: '10.19.89.20'
  end

  conf.vm.define :web, primary: true do |node|
    configure_web_vm node, host: 'dev-web70', ip: '10.19.89.14'
    node.vm.network :forwarded_port, guest: 6379, host: 6379
  end

  conf.vm.define :web56, autostart: false do |node|
    configure_web_vm node, host: 'dev-web56', ip: '10.19.89.10', php_version: 56
    node.vm.network :forwarded_port, guest: 6380, host: 6380
  end

  conf.vm.define :web55, autostart: false do |node|
    configure_web_vm node, host: 'dev-web55', ip: '10.19.89.11', php_version: 55
    node.vm.network :forwarded_port, guest: 6381, host: 6381
  end

  conf.vm.define :web54, autostart: false do |node|
    configure_web_vm node, host: 'dev-web54', ip: '10.19.89.12', php_version: 54
    node.vm.network :forwarded_port, guest: 6382, host: 6382
  end

  conf.vm.define :db51, autostart: false do |node|
    configure_db_vm node, host: 'dev-db51', ip: '10.19.89.21', mysql_version: 51
  end

  conf.vm.define :solr, autostart: false do |node|
    configure_solr_vm node, host: 'dev-solr', ip: '10.19.89.30'
  end
end
