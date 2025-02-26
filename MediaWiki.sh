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

# Installation des dépendances pour MediaWiki
echo "Installation des dépendances pour MediaWiki..."
apt install -y imagemagick php-intl php-mbstring php-xml
systemctl restart apache2

# Configuration de la base de données pour MediaWiki
DB_NAME="mediawiki"
DB_USER="wiki_user"
DB_PASS="WikiPass"

if ! mysql -e "USE $DB_NAME" &>/dev/null; then
    echo "Création de la base de données pour MediaWiki..."
    mysql -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
fi

# Téléchargement et installation de MediaWiki
echo "Téléchargement et installation de MediaWiki..."
cd /var/www/html
wget https://releases.wikimedia.org/mediawiki/1.41/mediawiki-1.41.0.tar.gz
 tar -xvzf mediawiki-1.41.0.tar.gz
ln -s mediawiki-1.41.0 mediawiki
chown -R www-data:www-data mediawiki-1.41.0
chmod -R 755 mediawiki-1.41.0

# Finalisation
echo "Installation de MediaWiki terminée !"
echo "Accédez à MediaWiki : http://$(hostname -I | awk '{print $1}')/mediawiki"
echo "Base de données : $DB_NAME / Utilisateur : $DB_USER / Mot de passe : $DB_PASS"
