
def configure_common (conf)
  conf.vm.box = 'bento/centos-6.7'

  # disable default /vagrant mount and mount at /server/vagrant
  conf.vm.synced_folder VAGRANT_DIR, '/vagrant', disabled: true
  mount_vmfs(conf, 'host-vagrant', VAGRANT_DIR, VAGRANT_DIR)

  # mount persistent shared cache storage on vm and bind sub-caches
  mount_vmfs(conf, 'host-cache', SHARED_DIR, SHARED_DIR)
  mount_bind(conf, SHARED_DIR + '/yum', '/var/cache/yum')
  
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
  assert_export(MOUNT_PATH + SITES_DIR)
  mount_nfs(node, 'host-www-sites', MOUNT_PATH + SITES_DIR, SITES_MOUNT)
  
  # bind sites directory shortcuts
  mount_bind(node, SITES_MOUNT, SITES_DIR)
  mount_bind(node, SITES_MOUNT, BASE_DIR + SITES_DIR)
  mount_bind(node, SITES_MOUNT, MOUNT_PATH + SITES_DIR)
  
  # bind localhost pub directory
  mount_bind(node, SITES_MOUNT + '/00_localhost/pub', '/var/www/html')
  
  # bind apache sites.d configuration directory
  mount_bind(node, VAGRANT_DIR + '/etc/httpd/sites.d', '/etc/httpd/sites.d')

  # setup guest provisioners
  bootstrap_sh(node, ['node', 'web'], { php_version: php_version })
  service(node, 'httpd', 'start')
  service(node, 'nginx', 'start')
  service(node, 'redis', 'start')
  
  # run vhosts.sh on every reload
  node.vm.provision :shell, run: 'always' do |conf|
    conf.name = "vhosts.sh"
    conf.inline = "/server/vagrant/bin/vhosts.sh"
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
  assert_export(MOUNT_PATH + '/mysql')
  mount_nfs(node, 'host-mysql-data', local_data_dir_name, '/var/lib/mysql/data')

  # setup guest provisioners
  bootstrap_sh(node, ['node', 'db'], { mysql_version: mysql_version })
  service(node, 'mysqld', 'start')
end

def configure_solr_vm (node, host: nil, ip: nil)
  node.vm.hostname = host
  node.vm.network :private_network, ip: ip
  assert_hosts_entry host, ip

  # setup guest provisioners
  bootstrap_sh(node, ['node', 'solr'])
end
