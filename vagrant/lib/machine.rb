
def configure_common (conf)
  conf.vm.box = 'bento/centos-6.7'

  # disable default /vagrant mount and mount at /server/vagrant
  conf.vm.synced_folder VAGRANT_DIR, '/vagrant', disabled: true
  mount_vmfs(conf, 'host-vagrant', VAGRANT_DIR, VAGRANT_DIR)

  # mount persistent shared cache storage on vm and bind sub-caches
  mount_vmfs(conf, 'host-cache', CACHE_DIR, CACHE_DIR)
  mount_bind(conf, CACHE_DIR + '/yum', '/var/cache/yum')
  
  # configure default RAM and number of CPUs allocated to vm
  vm_set_ram(conf, 2048)
  vm_set_cpu(conf, 2)

  # so we can connect to remote servers from inside the vm
  conf.ssh.forward_agent = true
end

def configure_web_vm (node, host: nil, ip: nil)
  node.vm.hostname = host
  node.vm.network :private_network, ip: ip

  # verify exports and mount nfs sites location
  assert_export(SERVER_MOUNT + SITES_DIR)
  mount_nfs(node, 'host-www-sites', SERVER_MOUNT + SITES_DIR, SITES_MOUNT)
  
  # bind sites directory shortcuts
  mount_bind(node, SITES_MOUNT, SITES_DIR)
  mount_bind(node, SITES_MOUNT, BASE_DIR + SITES_DIR)
  mount_bind(node, SITES_MOUNT, SERVER_MOUNT + SITES_DIR)
  
  # bind localhost pub directory
  mount_bind(node, SITES_MOUNT + '/00_localhost/pub', '/var/www/html')
  
  # bind apache sites.d configuration directory
  mount_bind(node, VAGRANT_DIR + '/etc/httpd/sites.d', '/etc/httpd/sites.d')

  # setup guest provisioners
  bootstrap_sh(node, ['node', 'web', 'sites'])
  service(node, 'httpd', 'start')
  service(node, 'nginx', 'start')
  service(node, 'redis', 'start')
end

def configure_db_vm (node, host: nil, ip: nil)
  node.vm.hostname = host
  node.vm.network :private_network, ip: ip

  vm_set_ram(node, 4096)

  # verify exports and mount nfs mysql data directory
  assert_export(SERVER_MOUNT + '/mysql')
  mount_nfs(node, 'host-mysql-data', SERVER_MOUNT + '/mysql/data', '/var/lib/mysql/data')

  # setup guest provisioners
  bootstrap_sh(node, ['node', 'db'])
  service(node, 'mysqld', 'start')
end

def configure_solr_vm (node, host: nil, ip: nil)
  node.vm.hostname = host
  node.vm.network :private_network, ip: ip

  # setup guest provisioners
  bootstrap_sh(node, ['node', 'solr'])
end
