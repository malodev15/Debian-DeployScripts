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
echo "Installation des dépendances..."
apt install -y apt-transport-https curl gnupg software-properties-common

# Ajout du dépôt FusionInventory
echo "Ajout du dépôt FusionInventory..."
wget -q -O- https://repo.fusioninventory.org/fusioninventory.gpg.key | gpg --dearmor -o /usr/share/keyrings/fusioninventory-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/fusioninventory-keyring.gpg] https://repo.fusioninventory.org/debian/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/fusioninventory.list
apt update

# Installation de FusionInventory
echo "Installation de FusionInventory..."
apt install -y fusioninventory-agent fusioninventory-agent-task-network fusioninventory-agent-task-deploy

# Configuration de l'agent
echo "Configuration de FusionInventory..."
config_file="/etc/fusioninventory/agent.cfg"
sed -i "s|;server =.*|server = http://$(hostname -I | awk '{print $1}')/glpi/plugins/fusioninventory/|" $config_file
sed -i "s|# local = no|local = yes|" $config_file

# Activation et démarrage du service
echo "Activation et démarrage de FusionInventory Agent..."
systemctl enable fusioninventory-agent
systemctl restart fusioninventory-agent

# Finalisation
echo "Installation de FusionInventory terminée !"
echo "Assurez-vous que le plugin FusionInventory est activé sur GLPI."