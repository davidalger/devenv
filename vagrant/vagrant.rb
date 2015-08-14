# -*- mode: ruby -*-
# vi: set ft=ruby :

base_dir = File.dirname(__FILE__)

Vagrant.require_version '>= 1.3.5'
Vagrant.configure(2) do |config|
  
  config.vm.box = 'chef/centos-6.5'
  config.vm.synced_folder base_dir, '/vagrant'
  
  config.vm.provision :file, source: "~/.gitignore", destination: ".gitignore"
  config.vm.provision :file, source: base_dir + '/etc/profile.sh', destination: ".bash_profile"
  
  config.vm.define :web, primary: true do |node|
    node.vm.hostname = 'dev-web'
    node.vm.network :private_network, ip: '10.19.89.10'
    node.vm.network :forwarded_port, guest: 80, host: 8080
    node.vm.synced_folder File.dirname(base_dir) + '/sites', '/var/www/sites', group: 'root', owner: 'root'
    
    node.vm.provision :shell do |sh|
      sh.name = 'bootstrap.sh'
      sh.inline = '/vagrant/scripts/bootstrap.sh "$@"'
      sh.args = ['web', 'sites']
    end
  end
  
  config.vm.define :db, primary: true do |node|
    node.vm.hostname = 'dev-db'
    node.vm.network :private_network, ip: '10.19.89.11'
    node.vm.synced_folder File.dirname(base_dir) + '/mysql', '/var/mysql/data', group: 'root', owner: 'root'
    
    node.vm.provision :shell do |sh|
      sh.name = 'bootstrap.sh'
      sh.inline = '/vagrant/scripts/bootstrap.sh "$@"'
      sh.args = ['db']
    end
  end

  config.vm.provider :virtualbox do |vm|
    vm.memory = 2048
    vm.cpus = 2
  end

  config.vm.provider :vmware_fusion do |vm|
    vm.vmx['memsize'] = 2048
    vm.vmx['numvcpus'] = 2
  end
end
