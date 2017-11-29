# Development Environment

This setup relies on Vagrant and VirtualBox (or [VMWare Fusion](#vmware-provider) if that's what you prefer) running on Mac OS X to power the virtualized developer environment. These dependencies are installed as part of the setup process using [Homebrew](http://brew.sh) and [Homebrew Cask](http://caskroom.io).

It is setup with different machines running different versions of PHP (PHP 7.0 is the default machine). The machines provide all the necessary components to build on Magento 1 and Magento 2, including support for running multiple PHP / MySql versions side-by-side if necessary ([see below for details](#virtual-machines)). The nodes run a traditional LAMP stack, with Nginx sitting in front of Apache as a proxy for static assets. It also includes [Xdebug](http://xdebug.org) pre-configured to connect to your IDE on the host machine.

## System Requirements

* Mac OS X 10.11 or later
* An HFS+ **Case-sensitive** partition mounted at `/Volumes/Server` or `/server`

    *Note: The environment should install and run from a case-insensitive mount, but this is not recommended for two reasons: a) the majority of deployments are done to case-sensitive file-systems, so development done on a case-sensitive mount is less error prone (ex: autoloaders may find a class in development, then fail on production); b) mysql will behave differently as it pertains to [identifier case sensitivity](https://dev.mysql.com/doc/refman/5.0/en/identifier-case-sensitivity.html) potentially causing unexpected behavior*

## Environment Setup

1. The install process will install brew on the host machine for gathering dependencies where not already present. If you already have brew installed, however, it is recommended to run the following commands, then cleanup any major issues it reports:

    ```bash
    brew update
    brew doctor
    ```

2. Install technical dependencies and setup the environment, entering your account password when prompted (this may happen a few times):

    ```bash
    curl -s https://raw.githubusercontent.com/davidalger/devenv/master/vagrant/bin/install.sh | bash
    source /etc/profile
    ```

3. Run the following to start up the virtual machines. This may take a while on first run

    ```bash
    cd /server
    vagrant up
    ```

4. To SSH into the vm, you can use `vcd` or `vcd web` to connect and automatically mirror your working directory

### Optional Steps

1. Install the compass tools used for scss compilation

    ```bash
    sudo gem update --system
    sudo gem install compass
    ```

2. Generate an RSA key pair. The generated public key will be used to authenticate remote SSH connections

    ```bash
    ssh-keygen -f ~/.ssh/id_rsa
    ```

    *Note: When prompted, enter a memorable passphrase (you’ll need to use it later)*

3. Because of GitHub's rate limits on their API it can happen that Composer will silently fail when running the m2setup.sh tool. To prevent this from happening, create an OAuth token via the [GitHub Settings](https://github.com/settings/tokens) area in your GitHub account. You can read more about these tokens [here](https://github.com/blog/1509-personal-api-tokens). Add this token to the composer configuration by running:

    ```bash
    composer config -g github-oauth.github.com "<oauthtoken>"
    ```

4. Create a Magento 2 build available at m2.demo:

    ```bash
    vagrant ssh -- m2setup.sh --sampledata --hostname=m2.demo
    echo "10.19.89.14 m2.demo" | sudo tee -a /etc/hosts > /dev/null
    ```

### Quick Reference

| hostname      | ip           | role     | autostart | description                                        |
| ------------- | ------------ | -------- | --------- | -------------------------------------------------- |
| dev-host      | 10.19.89.1   | host     | n/a       | this is the host machine for the environment       |
| [dev-web71]   | 10.19.89.15  | app      | no        | App node running PHP 7.1 / Percona Server 5.6      |
| [dev-web70]   | 10.19.89.14  | app      | **yes**   | App node running PHP 7.0 / Percona Server 5.6      |
| [dev-web56]   | 10.19.89.10  | app      | no        | App node running PHP 5.6 / Percona Server 5.6      |
| [dev-web55]   | 10.19.89.11  | app      | no        | App node running PHP 5.5 / Percona Server 5.6      |

## Virtual Machines

### Web Application
This node is setup to run services required to run web applications. Nginx is setup to deliver static assets directly and act as a proxy for anything else. Apache is setup with mod_php to delivery the web application and sits behind Nginx on an internal port. Redis has been setup for a cache data store such that it never writes information to disk.

Run `vhosts.sh` to generate vhosts for all sites and reload apache. This will be automatically run once when the machine is provisioned, and may be subsequently run within the guest environment (use --help for available options).

The IP address of this node is fixed at `10.19.89.10`. This IP should be used in `/etc/hosts` on the host machine to facilitate loading applications running within the vm from a browser on the host.

#### Virtual Host Configuration
Virtual hosts are created automatically for each site by running the `vhosts.sh` script. These .conf files are based on a template, or may manually be configured on a per-site basis by placing a `.<service>.conf` file in the root site directory where `<service>` is the name of the service the file is to configure (such as nginx or httpd).
    
To configure the virtual host configuration and reload services, run `vhosts.sh` within the guest machine. Running `vhosts.sh --reset-config --reset-certs` will wipe out all generated certificates and service configuration, creating it from scratch.

The `vhosts.sh` script looks for the pretense of three locations within each directory contained by `/sites` to determine if a given directory found in `/sites` is in fact in need of a virtual host. These locations are as follows:

* /sites/example.dev/pub
* /sites/example.dev/html
* /sites/example.dev/htdocs

If any of these three paths exist, a virtual host will be created based on the template found in `/server/vagrant/etc/httpd/sites.d/__vhost.conf.template`. The `DocumentRoot` will be configured using the first of the above three paths found for a given site directory. The `ServerName` will match the name of the sites directory (example.dev above) and a wildcard `ServerAlias` is included to support relevant sub-domains. When a file is found at `/sites/example.dev/.vhost.conf` it will be used in leu of the template file. Any updates to this file will be applied to the host configuration on subsequent runs of the `vhosts.sh` script.

#### PHP Versions

The default web70 node has PHP 7.0.x from the IUS repository. PHP 5.6 is also available via the web56 node, but it will not start automatically. To use it, start via `vagrant up web56`, then configure your local hosts file to point the site needing this specific version of PHP to the correct machine instance.

#### SSL
When the `web` VM is provisioned, a root CA is automatically generated and stored at `/server/.shared/ssl/rootca/certs/ca.cert.pem` if it does not already exist.
During vhost discovery and configuration, a wildcard cert, signed by the root CA, is automatically generated for it. Nginx is configured accordingly.

This means that all vhosts support SSL on both the naked domain and any immediate subdomain. 
Since these certs are all signed by the persistent root CA, if the root CA is added to the host as a trusted cert, the SSL cert for any vhost will automatically be valid.

##### Mac
To add the generated root CA to your trusted certs list on the host machine, run this command (after vagrant up has been run):

```bash
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain /server/.shared/ssl/rootca/certs/ca.cert.pem
```

##### Windows
To add the generated root CA to your certificate manager on Windows you will need to copy the `ca.cert.pem` file to a location on your Windows system like `C:\certs\ca.cert.pem` and then open a Command Prompt window in Administrator mode to execute the following command

```bash
certutil –addstore -enterprise –f "Root" c:\certs\ca.cert.pem
```

### Database Server

Each machine has an instance of Percona Server 5.6.x installed. Since this is a development environment, the root mysql password has been left blank. The data from the default machine is persisted in `/server/mysql/data`, data from other nodes persisted at `/server/mysql/<NAME>` where `<NAME>` is the name of machine the data is for.

To allow for custom database settings without modifying the default my.cnf file directly, files found at `vagrant/etc/my.cnf.d/*.cnf` will be copied onto this node and are applied via the `!includedir` directive in the `/etc/my.cnf` defaults file. Example use case: create the file `vagrant/etc/my.cnf.d/lower_case_table_names.cnf` with the following contents and then re-provision the vm:

    [mysqld]
    lower_case_table_names = 1

***WARNING:*** Because data is persisted to the host machine via an NFS mount, attempts to forcefully shutdown (aka run `vagrant destroy`) a machine may cause data corruption and will fail subsequent mysql start operations unless the vm has first been halted and/or the mysql service stopped gracefully prior to vm destruction. The recommended sequence to wipe the vm and create from scratch is halt, destroy, then up.

#### Common Problems
##### Percona Server fails to start
When this happens you'll see something like the following when attempting to provision or boot the vm:

    TASK [Starting mysql service] **************************************************
    fatal: [web]: FAILED! => {"changed": false, "failed": true, "msg": "Starting MySQL (Percona Server). ERROR! The server quit without updating PID file (/var/lib/mysql/dev-web70.pid).\n"}

This happens (per above warning) when the mysql service fails to shutdown cleanly. To solve this issue, proceed through the following steps:

***WARNING:*** If this is done and there is a running mysql instance using these ib* files, irreversible data corruption could occur. Please be careful! These instructions assume you're working on the `web70` VM. Update the commands if you're working on a different VM.

1. Verify that Virtual Box reports NO instances of any of the VMs are still running before proceeding

    ```bash
    VBoxManage list runningvms | grep "Server_web70"
    ```

2. Restart the `rpc.lockd` service on the host

    ```bash
    sudo launchctl unload /System/Library/LaunchDaemons/com.apple.lockd.plist
    sudo launchctl load /System/Library/LaunchDaemons/com.apple.lockd.plist
    ```

    Starting in MacOS 10.12.4 the rpc.lockd service is protected by System Integrity Protection, preventing you from reloading it via launchctl. If you see the message `Operation not permitted while System Integrity Protection is engaged` you will need to kill the `rpc.lockd` service instead. The service configuration has KeepAlive enabled, so the desired effect is accomplised, although in a much more heavy-handed fashion. Do this by running `sudo kill <PID>` where `<PID>` is replaced with the number `lsof` (per following step) displays under the PID column for the `rpc.lockd` command.

3. Verify no locks exist on your `ib*` files (command should return nothing)

    ```bash
    sudo lsof /server/mysql/data/ib*
    ```

4. Destroy and restart your VM

    ```bash
    vagrant destroy -f web70
    vagrant up web70
    ```

If the above does not succeed in bringing it back online, try rebooting the host machine. If that still does not solve the issue, it is likely you will have to help mysqld out a bit with recovery. Check `/var/log/mysqld.log` for more info.

## Development Notes

### Session Storage
It is well recognized that PHP cannot store sessions on an NFS mount. Since `/var/www/sites/` is mounted in the vm via an NFS mount, this causes trouble with storing session files inside the document root. Magento 2 seems to handle this just fine and stores it's sessions in the configured session location. Magento 1 requires a workaround to function.

To workaround this issue, replace the `var/session` directory with a soft-link pointing at the default php session store:

```bash
rm -rf var/session
ln -s /var/lib/php/session var/session
```

Alternately, you may use an alternative session storage mechanism such as redis or memcached to store sessions and avoid the problem altogether.

## VMWare Provider

Using VMWare Fusion is a supported (but non-default) setup. There are additional steps involved to use it due to differences in how Virtual Box and VMX configure network interfaces and handle NFS mounts.

For NFS mounts to function, run the following to add the necessary exports to your `/etc/exports` file on the host machine and restart nfsd:

```bash
MAPALL="-mapall=$(id -u):$(grep ^admin: /etc/group | cut -d : -f 3)"
MOUNT_DIR="$(readlink /server || echo /server)"
printf "%s\n%s\n" \
    "$MOUNT_DIR/sites/ -alldirs -network 192.168.235.0 -mask 255.255.255.0 $MAPALL" \
    "$MOUNT_DIR/mysql/ -alldirs -network 192.168.235.0 -mask 255.255.255.0 $MAPALL" \
    | sudo tee -a /etc/exports > /dev/null
sudo nfsd restart
```

# License
This project is licensed under the Open Software License 3.0 (OSL-3.0). See included LICENSE file for full text of OSL-3.0
