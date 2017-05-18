##
 # Copyright © 2015 by David Alger. All rights reserved
 #
 # Licensed under the Open Software License 3.0 (OSL-3.0)
 # See included LICENSE file for full text of OSL-3.0
 #
 # http://davidalger.com/contact/
 ##

def configure_basebox (node, host: nil, ip: nil, memory: 4096, cpu: 2)
  node.vm.box = 'bento/centos-6.7'

  node.vm.hostname = host
  node.vm.network :private_network, ip: ip
  assert_hosts_entry host, ip

  # disable default /vagrant mount and mount at /server/vagrant
  node.vm.synced_folder VAGRANT_DIR, '/vagrant', disabled: true
  Mount.vmfs('host-vagrant', VAGRANT_DIR, VAGRANT_DIR)

  # mount persistent shared cache storage on vm and bind sub-caches
  Mount.vmfs('host-cache', SHARED_DIR, SHARED_DIR)
  Mount.bind(SHARED_DIR + '/yum', '/var/cache/yum')
  Mount.bind(SHARED_DIR + '/npm', '/var/cache/npm')

  # setup guest provisioners
  Mount.provision(node)
  ansible_play(node, 'basebox', {
    host_zoneinfo: File.readlink('/etc/localtime')
  })

  # configure default RAM and number of CPUs allocated to vm
  vm_set_ram(node, memory)
  vm_set_cpu(node, cpu)

  # so we can connect to remote servers from inside the vm
  node.ssh.forward_agent = true
end

def configure_web (node, php_version: 70)
  # verify exports and mount nfs sites location
  Mount.assert_export(MOUNT_PATH + SITES_DIR)
  Mount.nfs('host-www-sites', MOUNT_PATH + SITES_DIR, SITES_MOUNT)

  # bind localhost pub directory
  Mount.bind(SITES_MOUNT + '/__localhost/pub', '/var/www/html')

  # setup guest provisioners
  Mount.provision(node)
  ansible_play(node, 'web', {
    php_version: php_version,
    shared_ssl_dir: SHARED_DIR + '/ssl'
  })

  # run vhosts.sh on every reload
  node.vm.provision :shell, run: 'always' do |conf|
    conf.name = "vhosts.sh"
    conf.inline = "vhosts.sh --quiet"
  end
end

def configure_percona (node, data_dir: 'data')
  # default local data directory location
  local_data_dir_name = MOUNT_PATH + '/mysql/' + data_dir

  # verify exports and mount nfs mysql data directory
  Mount.assert_export(MOUNT_PATH + '/mysql')
  Mount.nfs('host-mysql-data', local_data_dir_name, '/var/lib/mysql')

  # setup guest provisioners
  Mount.provision(node)
  ansible_play(node, 'percona')

  # start mysqld on every reload (must happen here so mysqld starts after file-system is mounted)
  node.vm.provision :shell, run: 'always' do |conf|
    conf.name = "service mysql start"
    conf.inline = "service mysql start"
  end
end
