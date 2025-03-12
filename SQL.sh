#!/bin/bash

set -e

# Chemin vers le script Web.sh
web_script="/root/Web.sh"

# Vérification des services Apache, MariaDB et PHP
if ! command -v apache2 &> /dev/null || ! command -v mysql &> /dev/null || ! command -v php &> /dev/null; then
    echo "🔎 Apache2, MariaDB ou PHP non détecté. Exécution de Web.sh..."
    if [ -f "$web_script" ]; then
        bash "$web_script"
    else
        echo "❌ Erreur : $web_script introuvable."
        exit 1
    fi
else
    echo "✅ Services Web déjà installés."
fi

# Installation de phpMyAdmin
echo "🌐 Installation de phpMyAdmin..."
apt update
apt install -y phpmyadmin

# Création du lien symbolique si nécessaire
if [ ! -L "/var/www/html/phpmyadmin" ]; then
    ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
    systemctl restart apache2
fi

# Configuration du pare-feu (si UFW est installé)
if command -v ufw &> /dev/null; then
    echo "🔥 Ouverture des ports HTTP (80) et HTTPS (443)..."
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw reload
fi

# Affichage des informations d'accès
echo "✅ Installation terminée !"
echo "🌐 Accès phpMyAdmin : http://$(hostname -I | awk '{print $1}')/phpmyadmin"
echo "🛡️ Pensez à configurer vos utilisateurs MariaDB si nécessaire."
