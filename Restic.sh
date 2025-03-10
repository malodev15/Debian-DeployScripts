#!/bin/bash

set -e

# Chemin vers le script Web.sh
web_script="/root/Web.sh"

# Vérification d'Apache2, PHP et MariaDB
if ! command -v apache2 &>/dev/null || ! command -v mysql &>/dev/null || ! command -v php &>/dev/null; then
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
echo "Installation des dépendances..."
apt install -y curl unzip git

# Installation de Restic
echo "Installation de Restic..."
if ! command -v restic &>/dev/null; then
    apt install -y restic
    echo "Restic installé."
else
    echo "Restic est déjà installé."
fi

# Création du dossier de configuration Restic
mkdir -p /etc/restic

# Configuration de Restic (modifier selon vos besoins)
cat <<EOF > /etc/restic/config.env
RESTIC_REPOSITORY=/mnt/backup/restic
RESTIC_PASSWORD=SuperMotDePasse
EOF

# Création du répertoire de sauvegarde
mkdir -p /mnt/backup/restic
chown -R root:root /mnt/backup/restic
chmod -R 700 /mnt/backup/restic

# Installation de Resticker (Interface Web pour Restic)
echo "Installation de Resticker (interface Web)..."
RESTICKER_DIR="/var/www/resticker"

if [ ! -d "$RESTICKER_DIR" ]; then
    git clone https://github.com/emuell/resticker.git "$RESTICKER_DIR"
    chown -R www-data:www-data "$RESTICKER_DIR"
    chmod -R 755 "$RESTICKER_DIR"

    # Création du Virtual Host pour l'accès Web
    cat <<EOL > /etc/apache2/sites-available/resticker.conf
<VirtualHost *:3000>
    ServerAdmin admin@localhost
    DocumentRoot $RESTICKER_DIR

    <Directory $RESTICKER_DIR>
        Require all granted
        AllowOverride All
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/resticker_error.log
    CustomLog \${APACHE_LOG_DIR}/resticker_access.log combined
</VirtualHost>
EOL

    a2ensite resticker
    systemctl reload apache2
    echo "Resticker est configuré sur le port 3000."
else
    echo "Resticker est déjà installé."
fi

# Création d'un premier backup test
echo "Création d'un backup test..."
source /etc/restic/config.env
restic init

echo "Installation de Restic et Resticker terminée !"
echo "Accédez à l'interface Web : http://$(hostname -I | awk '{print $1}'):3000"