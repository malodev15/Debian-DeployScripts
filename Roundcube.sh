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

# Installation de Roundcube et des dépendances
echo "Installation de Roundcube..."
apt install -y roundcube roundcube-core roundcube-mysql roundcube-plugins

# Configuration de la base de données Roundcube
DB_NAME="roundcube"
DB_USER="roundcube"
DB_PASS="RoundcubePass"

# Création de la base de données si elle n'existe pas
if ! mysql -e "USE $DB_NAME" &>/dev/null; then
    echo "Création de la base de données pour Roundcube..."
    mysql -e "CREATE DATABASE $DB_NAME;"
    mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    mysql $DB_NAME < /usr/share/roundcube/SQL/mysql.initial.sql
fi

# Configuration d'Apache pour Roundcube
echo "Configuration d'Apache pour Roundcube..."
ln -s /etc/roundcube/apache.conf /etc/apache2/conf-enabled/roundcube.conf
systemctl reload apache2

# Finalisation
echo "Installation et configuration de Roundcube terminées !"
echo "Accédez à l'interface : http://$(hostname -I | awk '{print $1}')/roundcube"
echo "Base de données : $DB_NAME / Utilisateur : $DB_USER / Mot de passe : $DB_PASS"
