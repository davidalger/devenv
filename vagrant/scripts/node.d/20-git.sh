# install and configure git
set -e

yum install -y -q git
git config --global core.excludesfile /etc/.gitignore_global
