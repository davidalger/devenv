##
 # Copyright © 2015 by David Alger. All rights reserved
 # 
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 # 
 # http://davidalger.com/contact/
 ##

def configure_common (conf)
  conf.vm.box = 'bento/centos-6.7'

  # disable default /vagrant mount and mount at /server/vagrant
  conf.vm.synced_folder VAGRANT_DIR, '/vagrant', disabled: true
  Mount.vmfs('host-vagrant', VAGRANT_DIR, VAGRANT_DIR)

  # mount persistent shared cache storage on vm and bind sub-caches
  Mount.vmfs('host-cache', SHARED_DIR, SHARED_DIR)
  Mount.bind(SHARED_DIR + '/yum', '/var/cache/yum')
  Mount.bind(SHARED_DIR + '/npm', '/var/cache/npm')
  # Mount.bind(SHARED_DIR + '/phpenv', '/root/.phpenv')
  # Mount.bind(SHARED_DIR + '/phpenv', '/home/vagrant/.phpenv')

  # configure default RAM and number of CPUs allocated to vm
  vm_set_ram(conf, 2048)
  vm_set_cpu(conf, 2)

  # so we can connect to remote servers from inside the vm
  conf.ssh.forward_agent = true
end

def configure_web_vm (node, host: nil, ip: nil, php_version: nil)
  node.vm.hostname = host
  node.vm.network :private_network, ip: ip
  assert_hosts_entry host, ip

  # verify exports and mount nfs sites location
  Mount.assert_export(MOUNT_PATH + SITES_DIR)
  Mount.nfs('host-www-sites', MOUNT_PATH + SITES_DIR, SITES_MOUNT)
  
  # bind sites directory shortcuts
  Mount.bind(SITES_MOUNT, SITES_DIR)
  Mount.bind(SITES_MOUNT, BASE_DIR + SITES_DIR)
  Mount.bind(SITES_MOUNT, MOUNT_PATH + SITES_DIR)
  
  # bind localhost pub directory
  Mount.bind(SITES_MOUNT + '/__localhost/pub', '/var/www/html')
  
  # setup guest provisioners
  Mount.provision(node)
  bootstrap_sh(node, ['node', 'web'], { php_version: php_version })
  
  # run vhosts.sh on every reload
  node.vm.provision :shell, run: 'always' do |conf|
    conf.name = "vhosts.sh"
    conf.inline = "vhosts.sh --quiet"
  end
end

def configure_db_vm (node, host: nil, ip: nil, mysql_version: nil)
  node.vm.hostname = host
  node.vm.network :private_network, ip: ip
  assert_hosts_entry host, ip

  vm_set_ram(node, 4096)

  # default local data directory location
  local_data_dir_name = MOUNT_PATH + '/mysql/data'
  
  # if non-default version specified, append to data dir path
  if mysql_version and mysql_version != 56
    local_data_dir_name = "#{local_data_dir_name}#{mysql_version}"
  end

  # verify exports and mount nfs mysql data directory
  Mount.assert_export(MOUNT_PATH + '/mysql')
  Mount.nfs('host-mysql-data', local_data_dir_name, '/var/lib/mysql/data')
  
  # setup guest provisioners
  Mount.provision(node)
  bootstrap_sh(node, ['node', 'db'], { mysql_version: mysql_version })
  
  # start mysqld on every reload (must happen here so mysqld starts after file-system is mounted)
  node.vm.provision :shell, run: 'always' do |conf|
    conf.name = "service mysqld start"
    conf.inline = "service mysqld start 2>&1 | grep -v \"/var/lib/mysql/data': Operation not permitted\""
  end
end

def configure_solr_vm (node, host: nil, ip: nil)
  node.vm.hostname = host
  node.vm.network :private_network, ip: ip
  assert_hosts_entry host, ip

  # setup guest provisioners
  Mount.provision(node)
end
