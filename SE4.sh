#!/bin/bash

set -e

# Vérification des droits root
if [ "$(id -u)" -ne 0 ]; then
    echo "Ce script doit être exécuté en tant que root."
    exit 1
fi

# Mise à jour du système
echo "🔄 Mise à jour du système..."
apt update && apt upgrade -y

# Installation des prérequis
echo "🔧 Installation des prérequis..."
apt install -y curl wget lsb-release

# Ajout du dépôt SambaEdu4
echo "📦 Ajout du dépôt SambaEdu4..."
wget -qO - http://wawadeb.crdp.ac-caen.fr/iso/debian/se4.gpg | apt-key add -
echo "deb http://wawadeb.crdp.ac-caen.fr/iso/debian/ sambaedu4 main" > /etc/apt/sources.list.d/sambaedu4.list

# Mise à jour des dépôts et installation de SambaEdu4
echo "📥 Installation de SambaEdu4..."
apt update
apt install -y sambaedu4

# Configuration initiale
echo "⚙️ Configuration de SambaEdu4..."
/usr/share/se3/sbin/setup-se3.sh

# Démarrage des services
echo "🚀 Démarrage des services SambaEdu4..."
systemctl enable slapd smbd nmbd apache2
systemctl restart slapd smbd nmbd apache2

echo "✅ Installation terminée !"
echo "Accédez à l'interface Web : http://$(hostname -I | awk '{print $1}')/se3"
