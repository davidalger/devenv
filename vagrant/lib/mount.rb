# Mounts a directory from the host machine on the vm at the designated path using an NFS mount
# Params:
# +conf+:: vagrant provisioning conf object
# +host_path+:: +String+ full path to directory on host machine
# +guest_path+:: +String+ mount location on virtual machine
# +read_only+:: +Boolean+ flag to indicate whether to mount in read-only mode
def mount_nfs (conf, id, host_path, guest_path, read_only = false)
  mount_options = 'vers=3,udp'
  if read_only == true
    mount_options = mount_options + ',ro'
  end
  conf.vm.synced_folder host_path, guest_path, id: id, create: true, nfs_export: false, type: 'nfs',
    :nfs => { mount_options: mount_options }
end

# Mounts directory from the host machine on the vm at the designated path using default vmfs
# Params:
# +conf+:: vagrant provisioning conf object
# +host_path+:: +String+ full path to directory on host machine
# +guest_path+:: +String+ mount location on virtual machine
# +mount_options+:: +Array+ additional mount options
def mount_vmfs (conf, id, host_path, guest_path, mount_options: [])
  FileUtils.mkdir_p host_path
  conf.vm.synced_folder host_path, guest_path, id: id, mount_options: mount_options
end