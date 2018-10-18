# Ansible Role: PHP-FPM

[![Build Status](https://travis-ci.org/davidalger/ansible-role-php-fpm.svg?branch=master)](https://travis-ci.org/davidalger/ansible-role-php-fpm)

Installs php-fpm from [IUS Community Project](http://ius.io) RPMs on RHEL / CentOS 7. Where archived verions of php are required, the ius-archive repository may be enabled.

Currently this role installs `php-fpm` pre-configured with defaults built around the Magento 2 application. Some of these defaults may be high than required for other applications of the php-fpm service. One of these areas would by the php-opcache defaults, which must be very high for high Magento 2 application performance and may otherwise be reduced. See `defaults/main.yml` and `vars/opcache.yml` for details.

## Requirements

None.

## Role Variables

    php_version: 72

Any php version supported by IUS RPMs may be specified: 55, 56, 70, 71, 72, etc. For older versions, `php_enablerepo: ius-archive` will also need to be specified.

See `defaults/main.yml` for complete list of variables available to customize the php-fpm installation.

## Dependencies

* `davidalger.repo_ius`

## Example Playbook

    - hosts: web-servers
      roles:
        - { role: davidalger.php_fpm, tags: php-fpm }

## License

This work is licensed under the MIT license. See LICENSE file for details.

## Author Information

This role was created in 2017 by [David Alger](http://davidalger.com/).
