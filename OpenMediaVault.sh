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
apt install -y gnupg apt-transport-https wget curl

# Ajout du dépôt OpenMediaVault
echo "Ajout du dépôt OpenMediaVault..."
wget -qO - https://packages.openmediavault.org/public/archive.key | gpg --dearmor -o /usr/share/keyrings/openmediavault-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/openmediavault-archive-keyring.gpg] https://packages.openmediavault.org/public shaitan main" > /etc/apt/sources.list.d/openmediavault.list

# Installation d'OpenMediaVault
echo "Installation d'OpenMediaVault..."
apt update
apt install -y openmediavault

# Configuration d'OpenMediaVault
echo "Configuration d'OpenMediaVault..."
omv-confdbadm populate

# Activation des services principaux
systemctl enable openmediavault-engined
systemctl start openmediavault-engined
systemctl enable nginx
systemctl start nginx

# Nettoyage après installation
echo "Nettoyage du système..."
apt autoremove -y && apt clean

# Finalisation
echo "Installation d'OpenMediaVault terminée !"
echo "Accédez à l'interface : http://$(hostname -I | awk '{print $1}')"
echo "Identifiants par défaut : admin / openmediavault"
