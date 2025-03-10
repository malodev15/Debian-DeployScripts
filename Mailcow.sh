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
echo "Installation des dépendances..."
apt install -y apt-transport-https curl gnupg lsb-release software-properties-common

# Installation de Mailcow (sans Docker)
echo "Installation de Mailcow..."

# Ajout du dépôt officiel
add-apt-repository ppa:mailcow/mailcow -y
apt update

# Installation des paquets nécessaires
apt install -y mailcow mailcow-core mailcow-backend mailcow-frontend

# Configuration de Mailcow
if [ ! -f /etc/mailcow/mailcow.conf ]; then
    echo "Configuration de Mailcow..."
    cp /usr/share/mailcow/mailcow.conf /etc/mailcow/mailcow.conf
    sed -i "s/MAILCOW_DOMAIN=.*/MAILCOW_DOMAIN=$(hostname -f)/" /etc/mailcow/mailcow.conf

    # Génération des certificats SSL (optionnel, personnalisable)
    mailcow-generate-certificate

    # Démarrage des services
    systemctl enable --now mailcow mailcow-backend mailcow-frontend
fi

# Finalisation
echo "Installation de Mailcow terminée !"
echo "Accédez à l'interface : https://$(hostname -I | awk '{print $1}')"