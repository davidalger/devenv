# install and configure git
set -e

yum install -y git
git config --global core.excludesfile /etc/.gitignore_global
