#!/bin/bash

set -e

# Vérification des droits root
if [ "$EUID" -ne 0 ]; then
    echo "Veuillez exécuter ce script en tant que root (ou avec sudo)."
    exit 1
fi

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation des dépendances
echo "Installation des dépendances..."
apt install -y curl

# Téléchargement et installation de Pi-hole
echo "Installation de Pi-hole..."
curl -sSL https://install.pi-hole.net | bash

# Activation et démarrage de Pi-hole
echo "Démarrage de Pi-hole..."
systemctl enable pihole-FTL
systemctl start pihole-FTL

# Affichage des informations d'accès
echo "Installation de Pi-hole terminée !"
echo "Interface d'administration : http://$(hostname -I | awk '{print $1}')/admin"
echo "Pour afficher le mot de passe administrateur : pihole -a -p"
