#!/bin/bash

set -e

echo "Mise à jour du système..."
apt update && apt upgrade -y

# Dépendances nécessaires
echo "Installation des dépendances..."
apt install -y wget gnupg2 lsb-release

# Ajout du dépôt officiel de FileZilla Server
echo "Ajout du dépôt FileZilla Server..."
wget https://download.filezilla-project.org/server/FileZilla_Server_latest_amd64.deb -O /tmp/filezilla-server.deb

# Installation de FileZilla Server
echo "Installation de FileZilla Server..."
dpkg -i /tmp/filezilla-server.deb || apt -f install -y

# Configuration du service
echo "Activation et démarrage de FileZilla Server..."
systemctl enable filezilla-server
systemctl start filezilla-server

# Création d'un utilisateur FTP
echo "Création d'un utilisateur FTP (user: ftpuser, password: ftp123)..."
adduser --disabled-password --gecos "" ftpuser
echo "ftpuser:ftp123" | chpasswd

# Configuration du pare-feu (si UFW est installé)
if command -v ufw &> /dev/null; then
    echo "Ouverture du port FTP (21) et du range passif (50000-51000)..."
    ufw allow 21/tcp
    ufw allow 50000:51000/tcp
    ufw reload
fi

# Affichage de l'état du service
echo "Statut de FileZilla Server :"
systemctl status filezilla-server --no-pager

echo "Installation de FileZilla Server terminée !"
echo "Accès FTP : ftp://$(hostname -I | awk '{print $1}')"
echo "Utilisateur : ftpuser | Mot de passe : ftp123"
