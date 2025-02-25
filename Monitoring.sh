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
echo "Installation des dépendances pour Zabbix et Wazuh..."
apt install -y apt-transport-https lsb-release gnupg curl

# Installation de Zabbix
echo "Installation de Zabbix..."
wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4+debian$(lsb_release -rs)_all.deb
apt install -y ./zabbix-release_6.0-4+debian$(lsb_release -rs)_all.deb
apt update
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent

# Configuration de la base de données Zabbix
DB_NAME="zabbix"
DB_USER="zabbix"
DB_PASS="ZabbixPass"

if ! mysql -e "USE $DB_NAME" &>/dev/null; then
    echo "Création de la base de données pour Zabbix..."
    mysql -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8 COLLATE utf8_bin;"
    mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
    mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"
    zcat /usr/share/doc/zabbix-sql-scripts/mysql/server.sql.gz | mysql -u$DB_USER -p$DB_PASS $DB_NAME
fi

# Configuration de Zabbix
echo "Configuration de Zabbix..."
systemctl enable zabbix-server zabbix-agent apache2
systemctl start zabbix-server zabbix-agent apache2

# Installation de Wazuh
echo "Installation de Wazuh..."
export WAZUH_MANAGER="localhost"
apt install -y gnupg apt-transport-https
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -

curl -sO https://packages.wazuh.com/4.11/wazuh-install.sh
chmod 744 wazuh-install.sh
./wazuh-install.sh -dw deb
curl -sO https://packages.wazuh.com/4.11/config.yml

cat ./config.yml <<EOL
nodes:
  indexer:
    - name: node-1
      ip: "127.0.0.1"

  server:
    - name: wazuh-1
      ip: "127.0.0.1"

  dashboard:
    - name: dashboard
      ip: "127.0.0.1"
EOL

./wazuh-istall.sh -g
./wazuh-istall.sh

# Démarrage de Wazuh
systemctl enable wazuh-manager wazuh-agent
systemctl start wazuh-manager wazuh-agent

# Finalisation
echo "Installation de Zabbix et Wazuh terminée !"
echo "Accédez à Zabbix : http://$(hostname -I | awk '{print $1}')/zabbix"
echo "Zabbix DB : $DB_NAME / User : $DB_USER / Pass : $DB_PASS"
