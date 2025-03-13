#NE PAS UTILISER EN PROD, CAR NON MAINTENU !
#SCRIPT NON FONCTIONNEL
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
apt install -y curl wget lsb-release gnupg2

# Ajout du dépôt LCS
echo "📦 Ajout du dépôt LCS..."
wget -qO - http://wawadeb.crdp.ac-caen.fr/iso/debian/se4.gpg | apt-key add -
echo "deb http://wawadeb.crdp.ac-caen.fr/iso/debian/ lcs main" > /etc/apt/sources.list.d/lcs.list

# Mise à jour des dépôts et installation de LCS
echo "📥 Installation de LCS..."
apt update
apt install -y lcs

# Configuration initiale de LCS
echo "⚙️ Configuration de LCS..."
/usr/share/lcs/scripts/setup-lcs.sh

# Activation et démarrage des services nécessaires
echo "🚀 Démarrage des services LCS..."
systemctl enable slapd apache2
systemctl restart slapd apache2

# Finalisation
echo "✅ Installation de LCS terminée !"
echo "Accédez à l'interface Web : http://$(hostname -I | awk '{print $1}')/lcs"
