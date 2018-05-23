##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

# Configures a node to use our role-based ansible play provisioner
# Params:
# +conf+:: vagrant provisioning conf object
# +playbook+:: +String+ name of playbook to run against node
def ansible_play (conf, playbook, extra_vars = {})
  conf.vm.provision :ansible_local do |conf|
    conf.playbook = "/vagrant/provisioning/#{playbook}.yml"
    conf.extra_vars = extra_vars
    conf.compatibility_mode = "2.0"
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
