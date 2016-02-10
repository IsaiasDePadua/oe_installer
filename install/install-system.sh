#!/bin/bash

# Terminate if any command fails
set -e

# Verify we are running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi


# SET UP SWAP SPACE

fallocate -l 1024M /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo /swapfile   none    swap    sw    0   0 >>/etc/fstab

sysctl vm.swappiness=10
echo 'vm.swappiness = 10' >> /etc/sysctl.conf


echo Performing package updates
apt-get -y update


echo Installing required system packages
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< 'mariadb-server-5.5 mysql-server/root_password password password'
debconf-set-selections <<< 'mariadb-server-5.5 mysql-server/root_password_again password password'
apt-get install -y git-core libapache2-mod-php5 php5-cli php5-mysql php5-ldap php5-curl php5-xsl libjpeg62 mariadb-server mariadb-client debconf-utils unzip xfonts-75dpi default-jre npm libgamin0 gamin openjdk-7-jdk xfonts-base ruby ant



# wkhtmltox is now bundled in the repository. Original download location is:
# wget http://download.gna.org/wkhtmltopdf/0.12/0.12.2.1/wkhtmltox-0.12.2.1_linux-trusty-amd64.deb
cd /vagrant/install
dpkg -i --force-depends wkhtmltox-0.12.2.1_linux-trusty-amd64.deb


npm install -g grunt-cli
ln -s /usr/bin/nodejs /usr/bin/node


#  Install pre-compiled FAM module and configure PHP to use it
sed -i "s/;   extension=msql.so/extension=fam.so/" /etc/php5/apache2/php.ini
sed -i "s/;   extension=msql.so/extension=fam.so/" /etc/php5/cli/php.ini
cp /vagrant/install/fam.so /usr/lib/php5/20121212/


# Enable display_errors and error logging for PHP, plus configure timezone
mkdir /var/log/php
chown www-data /var/log/php
sed -i "s/^display_errors = Off/display_errors = On/" /etc/php5/apache2/php.ini
sed -i "s/^display_startup_errors = Off/display_startup_errors = On/" /etc/php5/apache2/php.ini
sed -i "s/^;date.timezone =/date.timezone = \"Europe\/London\"/" /etc/php5/apache2/php.ini

sed -i "s/;error_log = php_errors.log/error_log = \/var\/log\/php_errors.log/" /etc/php5/apache2/php.ini
sed -i "s/^display_errors = Off/display_errors = On/" /etc/php5/cli/php.ini
sed -i "s/^display_startup_errors = Off/display_startup_errors = On/" /etc/php5/cli/php.ini
sed -i "s/;error_log = php_errors.log/error_log = \/var\/log\/php_errors.log/" /etc/php5/cli/php.ini
sed -i "s/^;date.timezone =/date.timezone = \"Europe\/London\"/" /etc/php5/cli/php.ini

a2enmod rewrite
cp /vagrant/install/bashrc /etc/bash.bashrc
source /vagrant/install/bashrc

# Bind mysql to accept connections from remote servers
## TODO: only do this for vagrant environments
sed -i "s/\s*bind-address\s*=\s*127\.0\.0\.1/bind-address    = 0.0.0.0/" /etc/mysql/my.cnf
/etc/init.d/mysql restart

echo --------------------------------------------------
echo SYSTEM SOFTWARE INSTALLED
echo Please check previous messages for any errors
echo --------------------------------------------------
