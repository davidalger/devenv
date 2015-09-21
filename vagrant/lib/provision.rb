# Configures a node to use our role-based provisioner
# Params:
# +conf+:: vagrant provisioning conf object
# +roles+:: +Array+ containing a list of roles to apply to the node in sequence
def bootstrap_sh (conf, roles, env = {})
  conf.vm.provision :shell do |conf|
    env = {
      base_dir: BASE_DIR,
      vagrant_dir: VAGRANT_DIR,
      shared_dir: SHARED_DIR,
      sites_dir: SITES_DIR,
      allowable_roles: ENV['VAGRANT_ALLOWABLE_ROLES'],
      bootstrap_log: '/var/log/bootstrap.log'
    }.merge(env)

    exports = ''
    env.each do |key, val|
      exports = %-#{exports}\nexport #{key.upcase}="#{val}";-
    end

    conf.name = 'bootstrap.sh'
    conf.inline = %-#{exports} #{VAGRANT_DIR}/scripts/bootstrap.sh "$@"-
    conf.args = roles
  end
end

# Performs a service call on the guest
# Params:
# +conf+:: vagrant provisioning conf object
# +name+:: name of service to operate on
# +call+:: name of action to take
def service (conf, name, call)
  
  # file used to filter the stderr output of service calls
  service_filter = "#{VAGRANT_DIR}/etc/service-filter.txt"
  
  conf.vm.provision :shell, run: 'always' do |conf|
    conf.name = "service #{name} #{call}"
    conf.inline = "
      service #{name} #{call} 2>&1 1> /tmp/service-stdout | grep -f #{service_filter} -v 1>&2 || true
      cat /tmp/service-stdout
    "
  end
end

# Configure the machines memory allocation
# Params:
# +conf+:: vagrant provisioning conf object
# +ram+:: amount of memory specified in megabytes
def vm_set_ram (conf, ram)
  conf.vm.provider('virtualbox') { |vm| vm.memory = ram; }
  conf.vm.provider('vmware_fusion') { |vm| vm.vmx['memsize'] = ram; }
end

# Configure the machines CPU allocation
# Params:
# +conf+:: vagrant provisioning conf object
# +cpu+:: number of CPUs to allocate
def vm_set_cpu(conf, cpu)
  conf.vm.provider('virtualbox') { |vm| vm.cpus = cpu; }
  conf.vm.provider('vmware_fusion') { |vm| vm.vmx['numvcpus'] = cpu; }
end
