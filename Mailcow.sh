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
apt install -y curl git apt-transport-https gnupg

# Installation de Docker
echo "Installation de Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
else
    echo "Docker est déjà installé."
fi

# Installation de Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Installation de Docker Compose..."
    apt install -y docker-compose
else
    echo "Docker Compose est déjà installé."
fi

# Installation de Mailcow
echo "Installation de Mailcow..."
MAILCOW_DIR="/opt/mailcow-dockerized"
if [ ! -d "$MAILCOW_DIR" ]; then
    git clone https://github.com/mailcow/mailcow-dockerized.git $MAILCOW_DIR
    cd $MAILCOW_DIR
    ./generate_config.sh
    docker-compose pull
    docker-compose up -d
else
    echo "Mailcow est déjà installé."
fi

# Finalisation
echo "Installation de Mailcow terminée !"
echo "Accédez à l'interface : https://$(hostname -I | awk '{print $1}')"
