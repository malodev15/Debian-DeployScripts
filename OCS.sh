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

# Installation des dépendances
echo "Installation des dépendances pour OCS Inventory..."
apt install -y make cmake build-essential perl libapache2-mod-perl2 libxml-simple-perl libcompress-zlib-perl libdbi-perl libdbd-mysql-perl libapache-dbi-perl libapache2-mod-php php-soap php-mbstring php-xml

# Configuration de la base de données pour OCS Inventory
DB_NAME="ocsweb"
DB_USER="ocsuser"
DB_PASS="OcsPass"

if ! mysql -e "USE $DB_NAME" &>/dev/null; then
    echo "Création de la base de données pour OCS Inventory..."
    mysql -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8 COLLATE utf8_general_ci;"
    mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
fi

# Téléchargement et installation d'OCS Inventory
echo "Téléchargement et installation d'OCS Inventory..."
cd /tmp
wget https://github.com/OCSInventory-NG/OCSInventory-Server/releases/download/2.12.1/OCSNG_UNIX_SERVER-2.12.1.tar.gz
tar -xvzf OCSNG_UNIX_SERVER-2.12.1.tar.gz
cd OCSNG_UNIX_SERVER-2.12.1

perl setup.sh <<EOF









EOF

# Configuration d'Apache
systemctl restart apache2

# Finalisation
echo "Installation d'OCS Inventory terminée !"
echo "Accédez à l'interface : http://$(hostname -I | awk '{print $1}')/ocsreports"
echo "Base de données : $DB_NAME / Utilisateur : $DB_USER / Mot de passe : $DB_PASS"
