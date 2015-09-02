# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'lib/config'
require_relative 'lib/mount'
require_relative 'lib/provision'

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

  conf.vm.box = 'bento/centos-6.7'

  # disable default /vagrant mount and mount at /server/vagrant
  conf.vm.synced_folder VAGRANT_DIR, '/vagrant', disabled: true
  mount_vmfs(conf, 'host-vagrant', VAGRANT_DIR, VAGRANT_DIR)

  # mount persistent shared cache storage on vm and bind sub-caches
  mount_vmfs(conf, 'host-cache', CACHE_DIR, CACHE_DIR)
  mount_bind(conf, CACHE_DIR + '/yum', '/var/cache/yum')
  
  # configure default RAM and number of CPUs allocated to vm
  vm_set_ram(conf, 2048)
  vm_set_cpu(conf, 2)

  # so we can connect to remote servers from inside the vm
  conf.ssh.forward_agent = true

  # declare database node
  conf.vm.define :db do |node|
    node.vm.hostname = 'dev-db'
    node.vm.network :private_network, ip: '10.19.89.20'
    vm_set_ram(node, 4096)

    # verify exports and mount nfs mysql data directory
    assert_export(SERVER_MOUNT + '/mysql')
    mount_nfs(node, 'host-mysql-data', SERVER_MOUNT + '/mysql/data', '/var/lib/mysql/data')

    # setup guest provisioners
    bootstrap_sh(node, ['node', 'db'])
    service(node, 'mysqld', 'start')
  end

  # declare application node
  conf.vm.define :web, primary: true do |node|
    node.vm.hostname = 'dev-web'
    node.vm.network :private_network, ip: '10.19.89.10'
    node.vm.network :forwarded_port, guest: 6379, host: 6379

    # verify exports and mount nfs sites location
    assert_export(SERVER_MOUNT + SITES_DIR)
    mount_nfs(node, 'host-www-sites', SERVER_MOUNT + SITES_DIR, SITES_MOUNT)
    
    # bind sites directory shortcuts
    mount_bind(node, SITES_MOUNT, SITES_DIR)
    mount_bind(node, SITES_MOUNT, BASE_DIR + SITES_DIR)
    mount_bind(node, SITES_MOUNT, SERVER_MOUNT + SITES_DIR)
    
    # bind localhost pub directory
    mount_bind(node, SITES_MOUNT + '/00_localhost/pub', '/var/www/html')
    
    # bind apache sites.d configuration directory
    mount_bind(node, VAGRANT_DIR + '/etc/httpd/sites.d', '/etc/httpd/sites.d')

    # setup guest provisioners
    bootstrap_sh(node, ['node', 'web', 'sites'])
    service(node, 'httpd', 'start')
    service(node, 'nginx', 'start')
    service(node, 'redis', 'start')
  end

  # declare solr node (optional)
  conf.vm.define :solr, autostart: false do |node|
    node.vm.hostname = 'dev-solr'
    node.vm.network :private_network, ip: '10.19.89.30'

    # setup guest provisioners
    bootstrap_sh(node, ['node', 'solr'])
  end
end
