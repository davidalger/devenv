##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

class Mount
  @@mounts = []

  # Mounts a directory from the host machine on the vm at the designated path using an NFS mount
  # Params:
  # +host_path+:: +String+ full path to directory on host machine
  # +guest_path+:: +String+ mount location on guest machine
  # +mount_options+:: +Array+ additional mount options
  def self.nfs (id, host_path, guest_path, mount_options: [])
    @@mounts += [{ type: 'nfs', id: id, host_path: host_path, guest_path: guest_path, mount_options: mount_options }]
  end

  # Mounts directory from the host machine on the vm at the designated path using default vmfs
  # Params:
  # +host_path+:: +String+ full path to directory on host machine
  # +guest_path+:: +String+ mount location on guest machine
  # +mount_options+:: +Array+ additional mount options
  def self.vmfs (id, host_path, guest_path, mount_options: [])
    @@mounts += [{ type: 'vmfs', id: id, host_path: host_path, guest_path: guest_path, mount_options: mount_options }]
  end

  # Binds location on guest machine from provided source to target
  # Params:
  # +source_path+:: +String+ full path to directory on host machine
  # +target_path+:: +String+ mount location on guest machine
  def self.bind (source_path, target_path)
    @@mounts += [{ type: 'bind', source_path: source_path, target_path: target_path }]
  end

  # Asserts that an entry is in the /etc/exports file to gaurantee that an NFS mount is possible
  # Params:
  # +host_path+:: +String+ path to required share directory
  def self.assert_export (host_path)
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

  # Sets up the vagrant configuration neccesary for the mounts configured via the Mount class
  # Params:
  # +conf+:: vagrant provisioning conf object
  def self.provision (conf)
    bindings = []

    @@mounts.each do |mount|
      case mount[:type]
        when 'nfs'
          provision_nfs(conf, mount)
        when 'vmfs'
          provision_vmfs(conf, mount)
        when 'bind'
          bindings += [mount]
      end
    end

    if bindings.count
      provision_bind(conf, bindings)
    end
  end

  def self.provision_nfs (conf, mount)
    conf.vm.synced_folder mount[:host_path], mount[:guest_path], id: mount[:id], create: true, nfs_export: false,
      type: 'nfs', :nfs => { mount_options: mount[:mount_options] }
  end
  private_class_method :provision_nfs

  def self.provision_vmfs (conf, mount)
    if mount[:id].start_with?('-')
      throw "Error: mount_vmfs id may not begin with a hyphen, id of #{mount[:id]} given"
    end

    FileUtils.mkdir_p mount[:host_path]   # ensure path on host is present
    conf.vm.synced_folder mount[:host_path], mount[:guest_path], id: mount[:id], mount_options: mount[:mount_options]
  end
  private_class_method :provision_vmfs

  def self.provision_bind (conf, bind)
    bind_sh = ""

    bind.each do | mount |
      bind_sh = %-#{bind_sh}
        echo "#{mount[:source_path]} =\> #{mount[:target_path]}"
        mkdir \-p "#{mount[:source_path]}" "#{mount[:target_path]}"
        sudo mount \-o bind "#{mount[:source_path]}" "#{mount[:target_path]}"
      -
    end

    conf.vm.provision :shell, run: 'always' do |conf|
      conf.name = "bind_sh"
      conf.inline = bind_sh
    end
  end
  private_class_method :provision_bind
end
