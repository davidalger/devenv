# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANT_DIR = File.dirname(__FILE__)
CACHE_DIR = BASE_DIR + '/.cache'
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
  mount_vmfs(conf, '-cache-yum', CACHE_DIR + '/yum/', '/var/cache/yum/')
  
  # configure RAM and CPUs allocated to virtual machines
  conf.vm.provider('virtualbox') { |vm| vm.memory = VM_RAM; vm.cpus = VM_CPU; }
  conf.vm.provider('vmware_fusion') { |vm| vm.vmx['memsize'] = VM_RAM; vm.vmx['numvcpus'] = VM_CPU; }
  
  # declare application node
  conf.vm.define :web, primary: true do |node|
    node.vm.hostname = 'dev-web'
    node.vm.network :private_network, ip: '10.19.89.10'
    node.vm.network :forwarded_port, guest: 80, host: 80
    
    mount_nfs(node, '-www-sites', BASE_DIR + '/sites', '/var/www/sites')
    mount_nfs(node, '-www-html', BASE_DIR + '/sites/00_localhost/pub', '/var/www/html')
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
