##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

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
      ssl_dir: SHARED_DIR + '/ssl',
      bootstrap_log: '/var/log/bootstrap.log',
      host_zoneinfo: File.readlink('/etc/localtime')
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

# Configure the guest memory allocation
# Params:
# +conf+:: vagrant provisioning conf object
# +ram+:: amount of memory specified in megabytes
def vm_set_ram (conf, ram)
  conf.vm.provider('virtualbox') { |vm| vm.memory = ram; }
  conf.vm.provider('vmware_fusion') { |vm| vm.vmx['memsize'] = ram; }
end

# Configure the guest CPU allocation
# Params:
# +conf+:: vagrant provisioning conf object
# +cpu+:: number of CPUs to allocate
def vm_set_cpu(conf, cpu)
  conf.vm.provider('virtualbox') { |vm| vm.cpus = cpu; }
  conf.vm.provider('vmware_fusion') { |vm| vm.vmx['numvcpus'] = cpu; }
end
