#!/bin/bash

set -e

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation des dépendances essentielles
echo "Installation des dépendances pour FreeIPA..."
apt install -y chrony curl wget dbus nscd

# Configuration de l'heure
systemctl enable chronyd --now

# Ajout du dépôt FreeIPA
echo "Ajout du dépôt FreeIPA..."
wget -qO - https://download.copr.fedorainfracloud.org/results/g/freeipa/freeipa-4.10/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/freeipa-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/freeipa-archive-keyring.gpg] https://download.copr.fedorainfracloud.org/results/g/freeipa/freeipa-4.10/debian-11/ /" > /etc/apt/sources.list.d/freeipa.list
apt update

# Installation de FreeIPA
apt install -y freeipa-server

# Configuration automatique de FreeIPA
hostnamectl set-hostname freeipa.local
ipa-server-install --unattended \
    --realm=EXAMPLE.LOCAL \
    --domain=example.local \
    --ds-password=DS_Password \
    --admin-password=Admin_Password

# Démarrage des services FreeIPA
systemctl enable ipa.service --now

# Finalisation
echo "Installation de FreeIPA terminée !"
echo "Accédez à l'interface web : https://$(hostname -I | awk '{print $1}')/"
echo "Admin user : admin / Password : Admin_Password"