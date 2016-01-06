#!/usr/bin/env bash

# Variables
# --------------------

MAGENTO_TABLE_PREFIX=""
MAGENTO_ROOT="/public/"

# Update Apt
# --------------------
apt-get update
apt-get install -y htop

# Install Apache & PHP
# --------------------
apt-get install -y apache2
apt-get install -y php5
apt-get install -y libapache2-mod-php5
apt-get install -y php5-mysqlnd php5-curl php5-xdebug php5-gd php5-intl php-pear php5-imap php5-mcrypt php5-ming php5-ps php5-pspell php5-recode php5-snmp php5-sqlite php5-tidy php5-xmlrpc php5-xsl php-soap

php5enmod mcrypt

# symlink vagrant root to www/html
# --------------------
rm -rf /var/www/html
ln -fs /vagrant${MAGENTO_ROOT} /var/www/html

# Replace contents of default Apache vhost
# --------------------
VHOST=$(cat <<EOF
<VirtualHost *:80>
  DocumentRoot "/var/www/html"
  ServerName localhost
  <Directory "/var/www/html">
    AllowOverride All
  </Directory>
</VirtualHost>
EOF
)

echo "$VHOST" > /etc/apache2/sites-enabled/000-default.conf

a2enmod rewrite
service apache2 restart

# Mysql
# --------------------
# Ignore the post install questions
export DEBIAN_FRONTEND=noninteractive
# Install MySQL quietly
apt-get -q -y install mysql-server-5.5

echo "Importing database..."
mysql -u root -e "CREATE DATABASE IF NOT EXISTS magento;"
mysql -u root magento < /vagrant/magento.sql
mysql -u root -e "USE magento; UPDATE ${MAGENTO_TABLE_PREFIX}core_config_data SET value = 'http://192.168.50.50/' WHERE path LIKE '%base_url';"
mysql -u root -e "USE magento; UPDATE ${MAGENTO_TABLE_PREFIX}core_config_data SET value = NULL WHERE path LIKE '%cookie_domain';"
mysql -u root -e "FLUSH PRIVILEGES;"

# Set permissions
# --------------------
echo "Setting Magento permissions..."
cd /var/www/html
mkdir var
curl -sL https://goo.gl/b1NkHW | sudo bash

# --------------------
echo "Done"