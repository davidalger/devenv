# Configures a node to use our role-based provisioner
# Params:
# +conf+:: vagrant provisioning conf object
# +roles+:: +Array+ containing a list of roles to apply to the node in sequence
def bootstrap_sh (conf, roles)
  conf.vm.provision :shell do |conf|
    env_vars = %-
      export BASE_DIR="/vagrant";
      export CACHE_DIR="/vagrant/.cache";
      export SITES_DIR="/var/www/sites";
      export ALLOWABLE_ROLES="#{ENV['VAGRANT_ALLOWABLE_ROLES']}";
      export PHP_VERSION="#{ENV['VAGRANT_PHP_VERSION']}";
    -
    conf.name = 'bootstrap.sh'
    conf.inline = %-#{env_vars} /vagrant/scripts/bootstrap.sh "$@"-
    conf.args = roles
  end
end

# Performs a service call on the guest
# Params:
# +conf+:: vagrant provisioning conf object
# +name+:: name of service to operate on
# +call+:: name of action to take
def service (conf, name, call)
  conf.vm.provision :shell, run: 'always' do |conf|
    conf.name = "service #{name} #{call}"
    conf.inline = "service #{name} #{call}"
  end
end

# Configure the machines memory allocation
# Params:
# +conf+:: vagrant provisioning conf object
# +ram+:: amount of memory specified in megabytes
def vm_set_ram (conf, ram = VM_RAM)
  conf.vm.provider('virtualbox') { |vm| vm.memory = ram; }
  conf.vm.provider('vmware_fusion') { |vm| vm.vmx['memsize'] = ram; }
end

# Configure the machines CPU allocation
# Params:
# +conf+:: vagrant provisioning conf object
# +cpu+:: number of CPUs to allocate
def vm_set_cpu(conf, cpu = VM_CPU)
  conf.vm.provider('virtualbox') { |vm| vm.cpus = cpu; }
  conf.vm.provider('vmware_fusion') { |vm| vm.vmx['numvcpus'] = cpu; }
end
