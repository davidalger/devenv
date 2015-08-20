# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANT_DIR = File.dirname(__FILE__)
CACHE_DIR = BASE_DIR + '/.cache'
FileUtils.mkdir_p BASE_DIR

# machine defaults
VM_RAM = 2048
VM_CPU = 2

require_relative 'lib/bootstrap'

# begin the configuration sequence
Vagrant.require_version '>= 1.3.5'
Vagrant.configure(2) do |config|
  
  config.vm.box = 'chef/centos-6.5'
  config.vm.synced_folder VAGRANT_DIR, '/vagrant'
  
  FileUtils.mkdir_p CACHE_DIR + '/yum/'
  config.vm.synced_folder CACHE_DIR + '/yum/', '/var/cache/yum/'
  
  # configure RAM and CPUs allocated to virtual machines
  config.vm.provider('virtualbox') { |vm| vm.memory = VM_RAM; vm.cpus = VM_CPU; }
  config.vm.provider('vmware_fusion') { |vm| vm.vmx['memsize'] = VM_RAM; vm.vmx['numvcpus'] = VM_CPU; }

  # declare application node
  config.vm.define :web, primary: true do |node|
    node.vm.hostname = 'dev-web'
    node.vm.network :private_network, ip: '10.19.89.10'
    node.vm.network :forwarded_port, guest: 80, host: 80

    FileUtils.mkdir_p BASE_DIR + '/sites'
    node.vm.synced_folder BASE_DIR + '/sites', '/var/www/sites', id: '-www-sites',
      mount_options: ['uid=48','gid=48']  # apache uid/gid
      
    FileUtils.mkdir_p BASE_DIR + '/sites/00_localhost'
    node.vm.synced_folder BASE_DIR + '/sites/00_localhost/pub', '/var/www/html', id: '-www-html',
      mount_options: ['uid=48','gid=48']  # apache uid/gid
    
    node.vm.provision('shell') { |conf| bootstrap_sh(conf, ['node', 'web', 'sites']) }
  end
  
  # declare database node
  config.vm.define :db do |node|
    node.vm.hostname = 'dev-db'
    node.vm.network :private_network, ip: '10.19.89.20'
    node.vm.network :forwarded_port, guest: 3306, host: 3306
    
    FileUtils.mkdir_p BASE_DIR + '/mysql/data'
    node.vm.synced_folder BASE_DIR + '/mysql/data', '/var/lib/mysql/data', id: '-mysql-data',
      mount_options: ['uid=27','gid=27']  # mysql uid/gid
    
    node.vm.provision('shell') { |conf| bootstrap_sh(conf, ['node', 'db']) }
  end
  
  # declare solr node (optional)
  config.vm.define :solr, autostart: false do |node|
    node.vm.hostname = 'dev-solr'
    node.vm.network :private_network, ip: '10.19.89.30'
    node.vm.provision('shell') { |conf| bootstrap_sh(conf, ['node', 'solr']) }
  end
end
