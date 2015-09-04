# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'lib/config'
require_relative 'lib/mount'
require_relative 'lib/provision'
require_relative 'lib/machine'

# configure environment paths
BASE_DIR = '/server'
SERVER_MOUNT = env_root(BASE_DIR)
VAGRANT_DIR = BASE_DIR + '/vagrant'
CACHE_DIR = BASE_DIR + '/.cache'
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
    configure_web_vm node, host: 'dev-web', ip: '10.19.89.10'
    node.vm.network :forwarded_port, guest: 6379, host: 6379
  end

  conf.vm.define :solr, autostart: false do |node|
    configure_solr_vm node, host: 'dev-solr', ip: '10.19.89.30'
  end
end
