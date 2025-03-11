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

# Installation des dépendances
echo "Installation des dépendances..."
apt install -y curl sqlite3 openssl

# Création d'un utilisateur dédié
echo "Création d'un utilisateur Vaultwarden..."
useradd -r -s /bin/false vaultwarden

# Téléchargement de Vaultwarden
echo "Téléchargement et installation de Vaultwarden..."
VAULTWARDEN_VERSION="1.30.5"
mkdir -p /opt/vaultwarden
wget "https://github.com/dani-garcia/vaultwarden/releases/download/${VAULTWARDEN_VERSION}/vaultwarden-${VAULTWARDEN_VERSION}-x86_64-unknown-linux-gnu.tar.gz" -P /tmp
tar -xzf /tmp/vaultwarden-${VAULTWARDEN_VERSION}-x86_64-unknown-linux-gnu.tar.gz -C /opt/vaultwarden
chown -R vaultwarden:vaultwarden /opt/vaultwarden

# Configuration du service systemd
echo "Création du service systemd..."
cat <<EOF > /etc/systemd/system/vaultwarden.service
[Unit]
Description=Vaultwarden (Bitwarden compatible server)
After=network.target

[Service]
User=vaultwarden
Group=vaultwarden
WorkingDirectory=/opt/vaultwarden
ExecStart=/opt/vaultwarden/vaultwarden
Environment="DATA_FOLDER=/opt/vaultwarden/data"
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Création du dossier de stockage
mkdir -p /opt/vaultwarden/data
chown -R vaultwarden:vaultwarden /opt/vaultwarden/data

# Démarrage du service
echo "Démarrage de Vaultwarden..."
systemctl daemon-reload
systemctl enable vaultwarden
systemctl start vaultwarden

# Finalisation
echo "Installation de Vaultwarden terminée !"
echo "Accédez à votre gestionnaire de mots de passe : http://$(hostname -I | awk '{print $1}'):8000"
