# Ansible Varnish 4.1

* For multiple varnish instance setups
* Installs varnish 4.1 from public RPM
* Supports RHEL 6 / 7

## Example Usage

* Single `prod` varnish instance setup:

        - varnish

* Double varnish instance setup:

        - { role: varnish, varnish_instance: { name: prod, port: 6081, admin_port: 6082 }}
        - { role: varnish, varnish_instance: { name: stage, port: 6091, admin_port: 6092 }}
