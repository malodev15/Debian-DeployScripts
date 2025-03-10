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
apt install -y openjdk-17-jre unzip curl

# Téléchargement de Keycloak
echo "Téléchargement de Keycloak..."
KEYCLOAK_VERSION="23.0.6"
wget "https://github.com/keycloak/keycloak/releases/download/${KEYCLOAK_VERSION}/keycloak-${KEYCLOAK_VERSION}.zip" -P /opt

# Extraction et installation
echo "Extraction de Keycloak..."
unzip /opt/keycloak-${KEYCLOAK_VERSION}.zip -d /opt
ln -s /opt/keycloak-${KEYCLOAK_VERSION} /opt/keycloak

# Création d'un utilisateur système
echo "Création d'un utilisateur keycloak..."
useradd -r -s /bin/false keycloak
chown -R keycloak:keycloak /opt/keycloak*

# Configuration du service systemd
echo "Configuration du service Keycloak..."
cat <<EOF > /etc/systemd/system/keycloak.service
[Unit]
Description=Keycloak Server
After=network.target

[Service]
User=keycloak
Group=keycloak
WorkingDirectory=/opt/keycloak
ExecStart=/opt/keycloak/bin/kc.sh start
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Création de l'administrateur Keycloak
echo "Création d'un administrateur Keycloak..."
export KEYCLOAK_ADMIN="admin"
export KEYCLOAK_ADMIN_PASSWORD="admin"
su - keycloak -c "/opt/keycloak/bin/kc.sh config credentials --user \$KEYCLOAK_ADMIN --password \$KEYCLOAK_ADMIN_PASSWORD"

# Démarrage et activation du service
echo "Démarrage de Keycloak..."
systemctl daemon-reload
systemctl enable keycloak
systemctl start keycloak

echo "Installation de Keycloak terminée !"
echo "Accédez à l'interface : http://$(hostname -I | awk '{print $1}'):8080"
echo "Identifiant : admin"
echo "Mot de passe : admin"
