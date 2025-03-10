#!/bin/bash

set -e

# Chemin vers le script Web.sh
web_script="/root/Web.sh"
ldap_script="/root/OpenLDAP.sh"

# Vérification d'Apache2, MariaDB et PHP
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
apt install -y curl gnupg2 lsb-release software-properties-common

# Ajout du dépôt ISC Kea
echo "Ajout du dépôt officiel de Kea DHCP..."
curl -1sLf 'https://dl.cloudsmith.io/public/isc/kea-2-4/cfg/setup/bash.deb.sh' | bash

# Installation de Kea DHCP
echo "Installation de Kea DHCP..."
apt install -y kea

# Activation du service Kea DHCP
systemctl enable kea-dhcp4-server
systemctl start kea-dhcp4-server

# Configuration de Kea DHCP (exemple de sous-réseau)
echo "Configuration de Kea DHCP..."

cat <<EOF > /etc/kea/kea-dhcp4.conf
{
    "Dhcp4": {
        "valid-lifetime": 3600,
        "subnet4": [
            {
                "subnet": "192.168.1.0/24",
                "pools": [
                    { "pool": "192.168.1.100 - 192.168.1.200" }
                ],
                "option-data": [
                    {
                        "name": "routers",
                        "data": "192.168.1.1"
                    },
                    {
                        "name": "domain-name-servers",
                        "data": "8.8.8.8, 8.8.4.4"
                    }
                ]
            }
        ],
        "interfaces-config": {
            "interfaces": ["eth0"]
        }
    }
}
EOF

# Redémarrage du service Kea
echo "Redémarrage du service Kea DHCP..."
systemctl restart kea-dhcp4-server

# Installation de Webmin (si non installé)
if ! command -v webmin &>/dev/null; then
    echo "Installation de Webmin..."
    bash "$ldap_script"
fi

# Ajout de Kea à Webmin
echo "Ajout de Kea DHCP à Webmin..."
mkdir -p /etc/webmin/kea
cat <<EOL > /etc/webmin/kea/config
dhcp4_conf=/etc/kea/kea-dhcp4.conf
dhcp4_pid=/run/kea/kea-dhcp4-server.pid
EOL

systemctl restart webmin

# Finalisation
echo "Installation de Kea DHCP terminée !"
echo "Accédez à l'interface Webmin : https://$(hostname -I | awk '{print $1}'):10000"
echo "Configuration DHCP : /etc/kea/kea-dhcp4.conf"
