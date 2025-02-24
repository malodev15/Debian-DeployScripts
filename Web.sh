#!/bin/bash

set -e

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation d'Apache2
echo "Installation d'Apache2..."
apt install -y apache2
systemctl enable apache2
systemctl start apache2

# Installation de MariaDB
echo "Installation de MariaDB Server..."
apt install -y mariadb-server
systemctl enable mariadb
systemctl start mariadb

# Installation de PHP et modules essentiels
echo "Installation de PHP..."
apt install -y php php-mysql libapache2-mod-php php-cli php-mbstring php-xml php-curl
systemctl restart apache2

# Installation de phpMyAdmin
echo "Installation de phpMyAdmin..."
apt install -y phpmyadmin
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
systemctl restart apache2

echo "Installation terminée !"
echo "- Apache2 : http://$(hostname -I | awk '{print $1}')"
echo "- phpMyAdmin : http://$(hostname -I | awk '{print $1}')/phpmyadmin"
echo "N'oubliez pas de sécuriser MariaDB avec ***mysql_secure_installation***"