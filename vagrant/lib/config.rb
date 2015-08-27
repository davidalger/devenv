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
