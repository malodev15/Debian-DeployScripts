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

# Installation de Samba
echo "Installation de Samba..."
apt install -y samba

# Configuration de Samba
smb_conf="/etc/samba/smb.conf"

# Sauvegarder l'ancienne configuration
cp "$smb_conf" "${smb_conf}.bak"

# Nouvelle configuration minimale
cat > "$smb_conf" <<EOF
[global]
   workgroup = WORKGROUP
   server string = Samba Server
   security = user

[partage]
   path = /srv/samba/share
   browsable = yes
   writable = yes
   guest ok = no
   read only = no
EOF

# Création du répertoire partagé
echo "Création du répertoire partagé..."
mkdir -p /srv/samba/share
chmod -R 0770 /srv/samba/share
chown -R nobody:nogroup /srv/samba/share

# Ajout d'un utilisateur Samba
echo "Création d'un utilisateur Samba..."
useradd -M -s /sbin/nologin sambauser
(echo "mot_de_passe"; echo "mot_de_passe") | smbpasswd -a sambauser

# Redémarrage des services
systemctl restart smbd
systemctl enable smbd

# Finalisation
echo "Installation et configuration de Samba terminées !"
echo "Accès au partage : \\$(hostname -I | awk '{print $1}')\partage"
echo "Utilisateur : sambauser / mot_de_passe"
