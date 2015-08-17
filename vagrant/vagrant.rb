# -*- mode: ruby -*-
# vi: set ft=ruby :

base_dir = File.dirname(__FILE__)
vm_mem = 2048
vm_cpu = 2

def bootstrap_sh (conf, roles)
  allowable_roles = %-#{ENV['VAGRANT_ALLOWABLE_ROLES']}-
  
  conf.name = 'bootstrap.sh'
  conf.inline = %-export ALLOWABLE_ROLES="#{allowable_roles}"; /vagrant/scripts/bootstrap.sh "$@"-
  conf.args = roles
end

Vagrant.require_version '>= 1.3.5'
Vagrant.configure(2) do |config|
  
  config.vm.box = 'chef/centos-6.5'
  config.vm.synced_folder base_dir, '/vagrant'
  
  config.vm.define :web, primary: true do |node|
    node.vm.hostname = 'dev-web'
    node.vm.network :private_network, ip: '10.19.89.10'
    node.vm.network :forwarded_port, guest: 80, host: 8080
    node.vm.synced_folder File.dirname(base_dir) + '/sites', '/var/www/sites', group: 'root', owner: 'root'
    node.vm.provision('shell') { |conf| bootstrap_sh(conf, ['node', 'web', 'sites']) }
  end
  
  config.vm.define :db do |node|
    node.vm.hostname = 'dev-db'
    node.vm.network :private_network, ip: '10.19.89.20'
    # node.vm.synced_folder File.dirname(base_dir) + '/mysql', '/var/lib/mysql', group: 'root', owner: 'root'
    node.vm.provision('shell') { |conf| bootstrap_sh(conf, ['node', 'db']) }
  end
  
  config.vm.define :solr, autostart: false do |node|
    node.vm.hostname = 'dev-solr'
    node.vm.network :private_network, ip: '10.19.89.30'
    node.vm.provision('shell') { |conf| bootstrap_sh(conf, ['node', 'solr']) }
  end
  
  config.vm.provider :virtualbox do |vm|
    vm.memory = vm_mem
    vm.cpus = vm_cpu
  end
  
  config.vm.provider :vmware_fusion do |vm|
    vm.vmx['memsize'] = vm_mem
    vm.vmx['numvcpus'] = vm_cpu
  end
end
