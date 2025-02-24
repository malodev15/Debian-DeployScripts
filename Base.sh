#!/bin/bash

set -e

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation et configuration d'OpenSSH
echo "Installation d'OpenSSH Server..."
apt install -y openssh-server
systemctl enable ssh
systemctl start ssh

# Configuration de base d'OpenSSH
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart ssh

# Installation de Webmin
echo "Installation de Webmin..."
wget -q http://www.webmin.com/download/deb/webmin-current.deb
apt install -y ./webmin-current.deb
rm webmin-current.deb
systemctl enable webmin
systemctl start webmin

# Informations finales
echo "Installation terminée !"
echo "- Webmin : https://$(hostname -I | awk '{print $1}'):10000"
echo "N'oubliez pas de vérifier les paramètres SSH."