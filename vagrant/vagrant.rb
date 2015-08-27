# -*- mode: ruby -*-
# vi: set ft=ruby :

# host machine configuration
VAGRANT_DIR = File.dirname(__FILE__)
BASE_DIR = File.dirname(VAGRANT_DIR)
CACHE_DIR = BASE_DIR + '/.cache'
SITES_DIR = BASE_DIR + '/sites'
FileUtils.mkdir_p BASE_DIR

# guest machine configuration
VM_RAM = 2048
VM_CPU = 2

VM_SITES_DIR = '/var/www/sites'

require_relative 'lib/mount'
require_relative 'lib/provision'

# begin the configuration sequence
Vagrant.require_version '>= 1.7.4'
Vagrant.configure(2) do |conf|

  conf.vm.box = 'chef/centos-6.5'

  mount_vmfs(conf, 'host-vagrant', VAGRANT_DIR, '/vagrant')
  mount_vmfs(conf, 'host-cache', CACHE_DIR, '/vagrant/.cache')

  mount_bind(conf, '/vagrant', '/server/vagrant')
  mount_bind(conf, '/vagrant/.cache/yum', '/var/cache/yum')
  
  # configure default RAM and number of CPUs allocated to vm
  vm_set_ram(conf)
  vm_set_cpu(conf)

  # so we can connect to remote servers from inside the vm
  conf.ssh.forward_agent = true

  # declare application node
  conf.vm.define :web, primary: true do |node|
    node.vm.hostname = 'dev-web'
    node.vm.network :private_network, ip: '10.19.89.10'
    node.vm.network :forwarded_port, guest: 80, host: 80
    node.vm.network :forwarded_port, guest: 6379, host: 6379

    assert_export(SITES_DIR)
    mount_nfs(node, 'host-www-sites', SITES_DIR, VM_SITES_DIR)

    mount_bind(node, VM_SITES_DIR, '/sites')
    mount_bind(node, VM_SITES_DIR, '/server/sites')
    mount_bind(node, VM_SITES_DIR, '/Volumes/Server/sites')
    mount_bind(node, VM_SITES_DIR + '/00_localhost/pub', '/var/www/html')
    mount_bind(node, '/vagrant/etc/httpd/sites.d', '/etc/httpd/sites.d')

    bootstrap_sh(node, ['node', 'web', 'sites'])
    service(node, 'httpd', 'start')
    service(node, 'nginx', 'start')
    service(node, 'redis', 'start')
  end

  # declare database node
  conf.vm.define :db do |node|
    node.vm.hostname = 'dev-db'
    node.vm.network :private_network, ip: '10.19.89.20'
    vm_set_ram(node, 4096)

    assert_export(BASE_DIR + '/mysql')
    mount_nfs(node, 'host-mysql-data', BASE_DIR + '/mysql/data', '/var/lib/mysql/data')

    bootstrap_sh(node, ['node', 'db'])
    service(node, 'nfslock', 'restart')
    service(node, 'mysqld', 'start')
  end

  # declare solr node (optional)
  conf.vm.define :solr, autostart: false do |node|
    node.vm.hostname = 'dev-solr'
    node.vm.network :private_network, ip: '10.19.89.30'

    bootstrap_sh(node, ['node', 'solr'])
  end
end
