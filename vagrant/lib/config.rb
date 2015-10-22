##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

# Validates path as a valid symlink pointing to our env or the containing directory of our env. Returns path
# Params:
# +base_dir+:: +String+ path to base directory or symlink to environment root
def base_dir (base_dir)
  # evaluates to true if is not either a valid directory a symlink pointing to a directory
  if !File.directory?(base_dir)
    throw 'Error: please create a /server link pointing to the environment root'
  end

  # assert base_dir points to our environment root
  if %-#{mount_path(base_dir)}/#{File.basename(VAGRANT_FILE)}- != VAGRANT_FILE
    throw "Error: #{base_dir} does not point at this environment root (did you link with a trailing slash?)"
  end
  
  return base_dir
end

# Resolves the mount path from the base_dir. Will return unchanged if base_dir is not a symlink.
# Params:
# +base_dir+:: +String+ path to base directory
def mount_path (base_dir)
  if File.symlink?(base_dir)
    base_dir = File.readlink(base_dir)
  end
  
  if !File.directory?(base_dir)
    throw "Error: #{base_dir} does not exist"
  end
  
  return base_dir
end

# Asserts that an entry is in the /etc/hosts file for the given host / ip combination
# Params:
# +host+:: +String+ hostname of the hosts file entry
# +ip+:: +String+ ip address of the hosts file entry
def assert_hosts_entry (host, ip)
  if not %x{grep -E '^#{ip}\\W+#{host}$' /etc/hosts}.strip!
    puts "==> host: Appending '#{ip} #{host}' to /etc/hosts file"
    system %-echo '#{ip} #{host}' | sudo tee \-a /etc/hosts > /dev/null-
  end
end

# Runs the host machine autoconfiguration routine
# Params:
def auto_config_host
  changes = false
  newsh = false

  assert_hosts_entry 'dev-host', '10.19.89.1'

  # place flag on host machine for use in common shell scripts
  if not File.exist?('/etc/.vagranthost')
    puts '==> host: Touching host indicator'
    system %-sudo touch /etc/.vagranthost-
    changes = true
  end

  # create symlink to profile.d scripts
  if not File.symlink?('/etc/profile.d')
    puts "==> host: Linking /etc/profile.d -> #{VAGRANT_DIR}/etc/profile.d"
    system %-sudo ln \-s #{VAGRANT_DIR}/etc/profile.d /etc/profile.d-
    changes = true
    newsh = true
  end

  # enable profile.d scripts on host
  if not %x{grep '## VAGRANT START ##' /etc/profile}.strip!
    puts "==> host: Configuring /etc/profile for running sub-scripts"

    profile_script=%-
for i in /etc/profile.d/*.sh ; do
    if [ \-r "$i" ]; then
        if [ "${\-#*i}" != "$\-" ]; then
            . "$i"
        else
            . "$i" >/dev/null 2>&1
        fi
    fi
done
unset i
-

    # append script to /etc/profile and then execute that new portion to pickup env configuration
    system %-
      printf "\n## VAGRANT START ##%s## VAGRANT END ##\n" '#{profile_script}'| sudo tee \-a /etc/profile > /dev/null
    -
    changes = true
    newsh = true
  end
  
  # add ~/.my.cnf if not present
  if not File.exist?("#{ENV['HOME']}/.my.cnf")
    puts "==> host: Creating ~/.my.cnf file with default info"
    system %-printf "[client]\nhost=dev\-db\nuser=root\npassword=\n" > ~/.my.cnf-
    if File.exist?("#{ENV['HOME']}/.mylogin.cnf")
      puts "==> host: Warning: the ~/.mylogin.cnf file may interfere with connection info set in ~/.my.cnf"
    end
    changes = true
  end
  
  # add exports for NFS mounts to /etc/exports
  if not (File.exist?('/etc/exports') and %x{grep '## VAGRANT START ##' /etc/exports}.strip!)
    puts "==> host: Adding entries to /etc/exports for NFS mounts"
    
    mapall = %x{printf $(id \-u):$(grep ^admin: /etc/group | cut \-d : \-f 3)}
    nfs_exports = %-
#{MOUNT_PATH}/sites/ \-alldirs \-network 10.19.89.0 \-mask 255.255.255.0 \-mapall=#{mapall}
#{MOUNT_PATH}/mysql/ \-alldirs \-network 10.19.89.0 \-mask 255.255.255.0 \-mapall=#{mapall}
-
    system %-
      printf "\n## VAGRANT START ##%s## VAGRANT END ##\n" '#{nfs_exports}' | sudo tee \-a /etc/exports > /dev/null
      sudo nfsd restart
    -
    changes = true
  end

  # verify virtualbox machine directory
  vbox_machine_dir = %x{VBoxManage list systemproperties | grep 'Default machine folder:' | sed 's/.*: *//g'}.strip!
  if vbox_machine_dir != "#{BASE_DIR}/.machines"
    puts "==> host: Setting global VirtualBox machine folder to /server/.machines"
    system %-VBoxManage setproperty machinefolder #{BASE_DIR}/.machines-
    changes = true
  end

  if changes
    puts '==> host: Auto configuration complete'
  end

  # prevent run if shell doesn't have expected env vars set from profile.d scripts or if changes require such
  if newsh or (changes == false && ENV['VAGRANT_IS_SETUP'] != 'true')
    puts 'Please re-run the command in a new shell... or type `source /etc/profile` and then try again'
    exit 1
  end
end
