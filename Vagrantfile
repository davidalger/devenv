##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

# only set if undefined (due to obscure cases where vagrant execs itself)
if not defined? VAGRANT_FILE
  
  # follow vagrant file symlink to absolute path
  if File.symlink?(__FILE__)
    vagrant_file = File.absolute_path(File.readlink(__FILE__))
  else
    vagrant_file = __FILE__
  end

  # if vagrant file is contained by a symlink parent, follow that to retrieve real absolute path
  if File.symlink?(File.dirname(vagrant_file))
    vagrant_file = File.readlink(File.dirname(vagrant_file)) + '/Vagrantfile'
  end

  # finally, declare the constant for use throughout scripts
  VAGRANT_FILE = vagrant_file
end

# kickoff the whole vagrant configuration routines
require_relative 'vagrant/vagrant'
