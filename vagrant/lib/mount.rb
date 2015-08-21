
# require the vagrant-bind-fs plugin or fail
unless Vagrant.has_plugin?('vagrant-bindfs')
  raise 'vagrant-bindfs is not installed! Please install with: vagrant plugin install vagrant-bindfs'
end

# Mounts a directory from the host machine on the vm at the designated path using an NFS mount and bind-fs
# Params:
# +conf+:: vagrant provisioning conf object
# +host_path+:: +String+ full path to directory on host machine
# +guest_path+:: +String+ mount location on virtual machine
# +read_only+:: +Boolean+ flag to indicate whether to mount in read-only mode
def mount_nfs (conf, id, host_path, guest_path, user = 'vagrant', group = 'vagrant', read_only = false)
  mount_options = 'vers=3,udp'
  if read_only == true
    mount_options = mount_options + ',ro'
  end
  unbound_path = '/var/nfs-unbound-' + id
  conf.vm.synced_folder host_path, unbound_path, id: id, create: true, nfs_export: false, type: 'nfs',
    :nfs => { mount_options: mount_options }
    
  conf.bindfs.bind_folder unbound_path, guest_path, force_user: user, force_group: group, create_as_user: true
end

# Mounts directory from the host machine on the vm at the designated path using default vmfs
# Params:
# +conf+:: vagrant provisioning conf object
# +host_path+:: +String+ full path to directory on host machine
# +guest_path+:: +String+ mount location on virtual machine
# +mount_options+:: +Array+ additional mount options
def mount_vmfs (conf, id, host_path, guest_path, mount_options = [])
  FileUtils.mkdir_p host_path
  conf.vm.synced_folder host_path, guest_path, id: id, mount_options: mount_options
end
