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

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation des dépendances pour GLPI
echo "Installation des dépendances pour GLPI..."
apt install -y php-cas php-cli php-curl php-gd php-intl php-xmlrpc php-bz2 php-ldap php-apcu php-mbstring php-imap php-zip php-soap php-json
systemctl restart apache2

# Configuration de la base de données pour GLPI
DB_NAME="glpi"
DB_USER="glpi_user"
DB_PASS="GLPIpass"

if ! mysql -e "USE $DB_NAME" &>/dev/null; then
    echo "Création de la base de données pour GLPI..."
    mysql -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
    mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
fi

# Téléchargement et installation de GLPI
echo "Téléchargement et installation de GLPI..."
cd /var/www/html
wget https://github.com/glpi-project/glpi/releases/download/10.0.14/glpi-10.0.14.tgz
 tar -xvzf glpi-10.0.14.tgz
chown -R www-data:www-data glpi
chmod -R 755 glpi

# Finalisation
echo "Installation de GLPI terminée !"
echo "Accédez à GLPI : http://$(hostname -I | awk '{print $1}')/glpi"
echo "Base de données : $DB_NAME / Utilisateur : $DB_USER / Mot de passe : $DB_PASS"
