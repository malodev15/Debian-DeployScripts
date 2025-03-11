#!/bin/bash

set -e

# Chemin vers le script Web.sh
web_script="/root/Web.sh"

# Vérification des services Apache, MariaDB et PHP
if ! command -v apache2 &> /dev/null || ! command -v mysql &> /dev/null || ! command -v php &> /dev/null; then
    echo "Apache2, MariaDB ou PHP non détecté. Exécution de Web.sh..."
    if [ -f "$web_script" ]; then
        bash "$web_script"
    else
        echo "Erreur : $web_script introuvable."
        exit 1
    fi
else
    echo "Services Web déjà installés."
fi

# Variables
GLPI_VERSION="10.0.14"
GLPI_DIR="/var/www/html/glpi"
GLPI_DATA_DIR="/var/glpi-data"

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation des dépendances requises
echo "Installation des dépendances GLPI..."
apt install -y unzip php-curl php-xml php-mbstring php-ldap php-imap php-apcu php-intl php-cli php-bz2 php-zip php-gd php-json

# Téléchargement et extraction de GLPI
echo "Téléchargement de GLPI $GLPI_VERSION..."
wget "https://github.com/glpi-project/glpi/releases/download/$GLPI_VERSION/glpi-$GLPI_VERSION.tgz" -P /tmp
tar -xzf /tmp/glpi-$GLPI_VERSION.tgz -C /var/www/html/
mv /var/www/html/glpi-$GLPI_VERSION $GLPI_DIR

# Déplacement du répertoire de données hors de la racine web
echo "Sécurisation des données en déplaçant les fichiers sensibles..."
mkdir -p $GLPI_DATA_DIR
mv $GLPI_DIR/files/* $GLPI_DATA_DIR
ln -s $GLPI_DATA_DIR $GLPI_DIR/files

# Sécurisation du répertoire public
echo "Sécurisation du répertoire web public..."
mkdir -p $GLPI_DIR/public
mv $GLPI_DIR/index.php $GLPI_DIR/public/

# Configuration des permissions
echo "Configuration des permissions..."
chown -R www-data:www-data $GLPI_DIR $GLPI_DATA_DIR
chmod -R 750 $GLPI_DIR $GLPI_DATA_DIR

# Configuration d'Apache
echo "Configuration d'Apache pour GLPI..."
cat <<EOF > /etc/apache2/sites-available/glpi.conf
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot $GLPI_DIR/public
    <Directory $GLPI_DIR/public>
        Require all granted
        AllowOverride All
    </Directory>

    # Protection des répertoires sensibles
    <Directory $GLPI_DIR/config>
        Require all denied
    </Directory>

    <Directory $GLPI_DIR/files>
        Require all denied
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
EOF

a2dissite 000-default
a2ensite glpi
systemctl reload apache2

# Sécurisation des sessions PHP
echo "Sécurisation des sessions PHP..."
PHP_INI="/etc/php/$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')/apache2/php.ini"
sed -i 's/^session.cookie_httponly =.*/session.cookie_httponly = On/' $PHP_INI

# Restart Apache2
systemctl restart apache2

echo "Installation sécurisée de GLPI terminée !"
echo "Accédez à : http://$(hostname -I | awk '{print $1}')"