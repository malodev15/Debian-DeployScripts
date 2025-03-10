#!/bin/bash

set -e

# Chemin vers le script OpenLDAP (dépendance)
ldap_script="/root/OpenLDAP.sh"

# Vérification d'OpenLDAP
if ! dpkg -l | grep -q slapd; then
    echo "OpenLDAP n'est pas installé. Exécution de OpenLDAP.sh..."
    if [ -f "$ldap_script" ]; then
        bash "$ldap_script"
    else
        echo "Erreur : $ldap_script introuvable."
        exit 1
    fi
else
    echo "OpenLDAP est déjà installé."
fi

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation des dépendances
echo "Installation des dépendances..."
apt install -y wget gnupg lsb-release apt-transport-https

# Ajout du dépôt FusionDirectory
echo "Ajout du dépôt FusionDirectory..."
wget -qO - https://repos.fusiondirectory.org/fusiondirectory.asc | apt-key add -
echo "deb http://repos.fusiondirectory.org/debian $(lsb_release -cs) main" > /etc/apt/sources.list.d/fusiondirectory.list

# Installation de FusionDirectory et des modules
echo "Installation de FusionDirectory..."
apt update
apt install -y fusiondirectory fusiondirectory-schema fusiondirectory-ldap-schema

# Chargement du schéma LDAP
echo "Ajout des schémas FusionDirectory à OpenLDAP..."
gunzip -c /usr/share/doc/fusiondirectory-schema/fusiondirectory.ldif.gz > /tmp/fusiondirectory.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /tmp/fusiondirectory.ldif

# Configuration de FusionDirectory
echo "Configuration de FusionDirectory..."
fusiondirectory-setup --check-config

# Redémarrage des services
echo "Redémarrage d'OpenLDAP et d'Apache..."
systemctl restart slapd
systemctl restart apache2

# Finalisation
echo "Installation de FusionDirectory terminée !"
echo "Accédez à l'interface : http://$(hostname -I | awk '{print $1}')/fusiondirectory"
