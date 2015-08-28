# Validates base_dir as a valid symlink pointing to our env and returns fully qualifed path to root
# Params:
# +base_link+:: +String+ path to base symlink
def env_root (base_link)
  # assert base_dir points to a valid symlink
  if not File.symlink?(base_link)
    throw 'Error: please create a /server link pointing to the environment root'
  end

  # assert base_dir points to our environment root
  if %-#{File.readlink(base_link)}/#{File.basename(VAGRANT_FILE)}- != VAGRANT_FILE
    throw "Error: #{base_link} link does not point at this environment root (did you link with a trailing slash?)"
  end

  return File.readlink(base_link)
end

def auto_config_host ()
  if not File.exist?('/etc/.vagranthost')
    puts '==> host: Touching host indicator'
    system %-sudo touch /etc/.vagranthost-
  end
  
  if not %x{grep '## VAGRANT START ##' /etc/profile}.strip!
    puts "==> host: Configuring /etc/profile for running sub-scripts"
    system %-
      printf "\n%s\n" \
'## VAGRANT START ##
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
## VAGRANT END ##' \
        | sudo tee \-a /etc/profile > /dev/null
    -
    changes = true
  end
  
  if not File.symlink?('/etc/profile.d')
    puts "==> host: Linking /etc/profile.d -> #{VAGRANT_DIR}/etc/profile.d"
    system %-sudo ln \-s #{VAGRANT_DIR}/etc/profile.d /etc/profile.d-
    changes = true
  end
end
