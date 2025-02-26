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
echo "Installation des dépendances FreePBX..."
apt install -y wget curl git sox mariadb-client mariadb-server php-pear php-cgi php-mbstring php-xml php-bcmath php-common php-curl php-gd php-mysql php-zip libapache2-mod-php ffmpeg

# Installation d'Asterisk
echo "Téléchargement et installation d'Asterisk..."
wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-20-current.tar.gz
tar -xvzf asterisk-20-current.tar.gz
cd asterisk-20.*
./configure --with-jansson-bundled
make && make install && make samples && make config
ldconfig

# Création de l'utilisateur Asterisk
useradd -m asterisk
chown -R asterisk:asterisk /var/lib/asterisk /var/spool/asterisk /var/log/asterisk /var/run/asterisk /etc/asterisk
sed -i 's/;runuser = asterisk/runuser = asterisk/' /etc/asterisk/asterisk.conf
sed -i 's/;rungroup = asterisk/rungroup = asterisk/' /etc/asterisk/asterisk.conf

# Redémarrage d'Asterisk
systemctl restart asterisk
systemctl enable asterisk

# Téléchargement et installation de FreePBX
echo "Téléchargement et installation de FreePBX..."
cd /usr/src
wget https://mirror.freepbx.org/modules/packages/freepbx/freepbx-16.0-latest.tgz
tar vxf freepbx-16.0-latest.tgz
cd freepbx
./start_asterisk start
./install -n

# Configuration d'Apache pour FreePBX
echo "Configuration d'Apache pour FreePBX..."
a2enmod rewrite
systemctl restart apache2

# Finalisation
echo "Installation de FreePBX terminée !"
echo "Accédez à l'interface : http://$(hostname -I | awk '{print $1}')"
