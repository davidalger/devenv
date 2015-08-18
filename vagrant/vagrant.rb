# -*- mode: ruby -*-
# vi: set ft=ruby :

# directory mounted at /vagrant in our machine and basis for all vagrant ops
base_dir = File.dirname(__FILE__)

# path to local cache directory used to share and persist certain machine data
cache_dir = File.dirname(base_dir) + '/.cache'
FileUtils.mkdir_p cache_dir

# virtual machine defaults
vm_mem = 2048
vm_cpu = 2

# Configures a node to use our role-based provisioner
# Params:
# +conf+:: vagrant provisioning conf object
# +roles+:: +Array+ containing a list of roles to apply to the node in sequence
def bootstrap_sh (conf, roles)
  allowable_roles = %-#{ENV['VAGRANT_ALLOWABLE_ROLES']}-
  
  conf.name = 'bootstrap.sh'
  conf.inline = %-export ALLOWABLE_ROLES="#{allowable_roles}"; /vagrant/scripts/bootstrap.sh "$@"-
  conf.args = roles
end

# begin the configuration sequence
Vagrant.require_version '>= 1.3.5'
Vagrant.configure(2) do |config|
  
  config.vm.box = 'chef/centos-6.5'
  config.vm.synced_folder base_dir, '/vagrant'
  
  FileUtils.mkdir_p cache_dir + '/yum/'
  config.vm.synced_folder cache_dir + '/yum/', '/var/cache/yum/'
  
  # configure RAM and CPUs allocated to virtual machines
  config.vm.provider('virtualbox') { |vm| vm.memory = vm_mem; vm.cpus = vm_cpu; }
  config.vm.provider('vmware_fusion') { |vm| vm.vmx['memsize'] = vm_mem; vm.vmx['numvcpus'] = vm_cpu; }

  # declare application node
  config.vm.define :web, primary: true do |node|
    node.vm.hostname = 'dev-web'
    node.vm.network :private_network, ip: '10.19.89.10'
    node.vm.network :forwarded_port, guest: 80, host: 8080
    node.vm.synced_folder File.dirname(base_dir) + '/sites', '/var/www/sites', group: 'root', owner: 'root'
    node.vm.provision('shell') { |conf| bootstrap_sh(conf, ['node', 'web', 'sites']) }
  end
  
  # declare database node
  config.vm.define :db do |node|
    node.vm.hostname = 'dev-db'
    node.vm.network :private_network, ip: '10.19.89.20'
    # node.vm.synced_folder File.dirname(base_dir) + '/mysql', '/var/lib/mysql', group: 'root', owner: 'root'
    node.vm.provision('shell') { |conf| bootstrap_sh(conf, ['node', 'db']) }
  end
  
  # declare solr node (optional)
  config.vm.define :solr, autostart: false do |node|
    node.vm.hostname = 'dev-solr'
    node.vm.network :private_network, ip: '10.19.89.30'
    node.vm.provision('shell') { |conf| bootstrap_sh(conf, ['node', 'solr']) }
  end
end
