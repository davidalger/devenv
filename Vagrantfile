# -*- mode: ruby -*-
# vi: set ft=ruby :

if not defined? VAGRANT_FILE
  if File.symlink?(__FILE__)
    vagrant_file = File.absolute_path(File.readlink(__FILE__))
    if File.symlink?(File.dirname(vagrant_file))
      vagrant_file = File.readlink(File.dirname(vagrant_file)) + '/Vagrantfile'
    end
  else
    vagrant_file = __FILE__
  end
  VAGRANT_FILE = vagrant_file
end
require_relative 'vagrant/vagrant'
