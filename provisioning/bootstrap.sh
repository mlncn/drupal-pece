#!/usr/bin/env bash
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y upgrade
apt-get -y install \
	php-codesniffer \
  unicode-data \
	rake
apt-get -y autoremove

cp -r /vagrant/provisioning/etc/* /etc/

php5enmod vagrant
# phpcs --config-set default_standard /vagrant/web/sites/all/modules/contrib/coder/coder_sniffer/Drupal/

# Create a local file folder inside the VM and symlink drupal's public file
# folder to upload files through the UI.
export FILES=/var/local/drupal
if [ ! -d $FILES ]; then
	mkdir -p $FILES
fi
chown -R www-data:staff $FILES
chmod -R g+w $FILES

if [ ! -L /vagrant/src/cnf/files ]; then
	ln -s $FILES /vagrant/src/cnf/files
fi

# Create the database.
if [ ! -d /var/lib/mysql/pece ]; then
	mysqladmin -u root create pece
fi

# Disable the system's default virtual host.
if [ -L /etc/apache2/sites-enabled/000-default.conf ]; then
	a2dissite 000-default
fi

# Enable the drupal website as the default virtual host.
if [ ! -L /etc/apache2/sites-enabled/drupal.conf ]; then
	a2ensite drupal
fi

service apache2 restart

# Clear the decks before we install everything
rm -rf /vagrant/node_modules

# Prepare src directory for the gulp build step, below.  If we don't clean
# it out, it doesn't clean up the markitup library enough and a patch fails.
rm -rf /vagrant/src/libraries/markitup
# Should probably clean up everything.

cd /vagrant

# From here on out, run as the vagrant user

su - vagrant <<'EOF'

cd /home/vagrant

curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh | bash
source /home/vagrant/.bashrc

cd /vagrant
source /home/vagrant/.bashrc
nvm install
source /home/vagrant/.bashrc

cd /vagrant
# npm install -g npm@3.x.x
npm install

node --version
npm --version

# npm install -g gulp

rm -rf /home/vagrant/.drush
git clone -b local_workflow_improvements --single-branch git://github.com/TallerWebSolutions/kraftwagen.git /home/vagrant/.drush/
drush cc drush

# cd /vagrant/node_modules/slug/ && npm install unicode

# This next command must be run interactively, it seems, until we rewrite the drush command (kw-s) that the gulp task 'setup' relies on...

# gulp setup

# And so everything that follows must be run manually too.

# Hack so it finds patches
ln -s src/patches patches

# gulp build

# gulp site-install

#gulp demo

echo "Now run: gulp setup && gulp build && gulp site-install && gulp demo"

EOF

