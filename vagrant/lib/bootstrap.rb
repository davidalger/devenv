# Configures a node to use our role-based provisioner
# Params:
# +conf+:: vagrant provisioning conf object
# +roles+:: +Array+ containing a list of roles to apply to the node in sequence
def bootstrap_sh (conf, roles)
  allowable_roles = %-#{ENV['VAGRANT_ALLOWABLE_ROLES']}-
  
  conf.name = 'bootstrap.sh'
  conf.inline = %-export ALLOWABLE_ROLES="#{allowable_roles}"; /vagrant/scripts/bootstrap.sh "$@"-
  conf.args = roles
end
