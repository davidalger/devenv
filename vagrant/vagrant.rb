# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANT_DIR = File.dirname(__FILE__)
CACHE_DIR = BASE_DIR + '/.cache'
SITES_DIR = BASE_DIR + '/sites'
FileUtils.mkdir_p BASE_DIR

# machine defaults
VM_RAM = 2048
VM_CPU = 2

require_relative 'lib/mount'
require_relative 'lib/provision'

# begin the configuration sequence
Vagrant.require_version '>= 1.7.4'
Vagrant.configure(2) do |conf|
  
  conf.vm.box = 'chef/centos-6.5'
  
  mount_vmfs(conf, '-vagrant', VAGRANT_DIR, '/vagrant')
  mount_vmfs(conf, '-cache', CACHE_DIR, '/vagrant/.cache')
  mount_vmfs(conf, '-cache-yum', CACHE_DIR + '/yum/', '/var/cache/yum/')
  
  # configure default RAM and number of CPUs allocated to virtual machines
  vm_set_ram(conf)
  vm_set_cpu(conf)
  
  # declare application node
  conf.vm.define :web, primary: true do |node|
    node.vm.hostname = 'dev-web'
    node.vm.network :private_network, ip: '10.19.89.10'
    node.vm.network :forwarded_port, guest: 80, host: 80
    node.vm.network :forwarded_port, guest: 6379, host: 6379
    
    mount_nfs(node, '-www-sites', SITES_DIR, '/var/www/sites')
    mount_nfs(node, '-www-html', SITES_DIR + '/00_localhost/pub', '/var/www/html')
    mount_vmfs(node, '-www-sites-conf', VAGRANT_DIR + '/etc/httpd/sites.d', '/var/httpd/sites.d')
    
    bootstrap_sh(node, ['node', 'web', 'sites'])
    service(node, 'httpd', 'start')
    service(node, 'nginx', 'start')
    service(node, 'redis', 'start')
  end
  
  # declare database node
  conf.vm.define :db do |node|
    node.vm.hostname = 'dev-db'
    node.vm.network :private_network, ip: '10.19.89.20'
    node.vm.network :forwarded_port, guest: 3306, host: 3306
    vm_set_ram(node, 4096)
    
    mount_nfs(node, '-mysql-data', BASE_DIR + '/mysql/data', '/var/lib/mysql/data')
    
    bootstrap_sh(node, ['node', 'db'])
    service(node, 'mysqld', 'start')
  end
  
  # declare solr node (optional)
  conf.vm.define :solr, autostart: false do |node|
    node.vm.hostname = 'dev-solr'
    node.vm.network :private_network, ip: '10.19.89.30'
    
    bootstrap_sh(node, ['node', 'solr'])
  end
end
