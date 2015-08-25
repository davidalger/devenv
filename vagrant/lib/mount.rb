# Mounts a directory from the host machine on the vm at the designated path using an NFS mount
# Params:
# +conf+:: vagrant provisioning conf object
# +host_path+:: +String+ full path to directory on host machine
# +guest_path+:: +String+ mount location on virtual machine
# +read_only+:: +Boolean+ flag to indicate whether to mount in read-only mode
def mount_nfs (conf, id, host_path, guest_path, read_only = false)
  
  # compute final list of nfs mount options
  mount_options = 'vers=3,udp'
  if read_only == true
    mount_options = mount_options + ',ro'
  end
  
  # configure the nfs mount using the built-in
  conf.vm.synced_folder host_path, guest_path, id: id, create: true, nfs_export: false, type: 'nfs',
    :nfs => { mount_options: mount_options }
  
  # bind host path on guest so absolute symlinks on host will correctly point to a valid location
  conf.vm.provision :shell, run: 'always' do |conf|
    conf.name = 'binding ' + guest_path
    conf.inline = %-
      mkdir \-p #{host_path}
      sudo mount \-o bind #{guest_path} #{host_path}
    -
  end
end

# Mounts directory from the host machine on the vm at the designated path using default vmfs
# Params:
# +conf+:: vagrant provisioning conf object
# +host_path+:: +String+ full path to directory on host machine
# +guest_path+:: +String+ mount location on virtual machine
# +mount_options+:: +Array+ additional mount options
def mount_vmfs (conf, id, host_path, guest_path, mount_options: [])
  FileUtils.mkdir_p host_path   # ensure path on host is present
  conf.vm.synced_folder host_path, guest_path, id: id, mount_options: mount_options
end

# Asserts that an entry is in the /etc/exports file to gaurantee that an NFS mount is possible
# Params:
# +host_path+:: +String+ path to required share directory
def assert_export (host_path)
  if File.exist?('/etc/exports') == false
    $stderr.puts "Error: /etc/exports does not exist. See /server/README.md for details"
    exit false
  end
  
  exports = File.readlines('/etc/exports')
  for line in exports
    if line.start_with?(host_path + '/ -alldirs')
      return true
    end
  end
  $stderr.puts "Error: /etc/exports is missing an entry for #{host_path}/. See /server/README.md for details"
  exit false
end
