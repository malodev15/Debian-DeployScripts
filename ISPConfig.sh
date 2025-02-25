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

# Installation des dépendances essentielles
echo "Installation des dépendances essentielles..."
apt install -y unzip curl git net-tools cron bash-completion haveged

# Téléchargement d'ISPConfig
echo "Téléchargement d'ISPConfig..."
cd /usr/local/src
wget -O ispconfig.tar.gz https://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz

tar -xvzf ispconfig.tar.gz
cd ispconfig3_install/install/

# Lancement de l'installation d'ISPConfig
echo "Installation d'ISPConfig en cours..."
php -q install.php <<EOF









EOF

# Finalisation
echo "Installation d'ISPConfig terminée !"
echo "Accédez à l'interface : https://$(hostname -I | awk '{print $1}'):8080"
echo "Identifiants : admin / votre_mot_de_passe"
