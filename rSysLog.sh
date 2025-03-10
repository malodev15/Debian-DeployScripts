#!/bin/bash

set -e

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation de Rsyslog
echo "Installation de Rsyslog..."
apt install -y rsyslog

# Activation des logs réseau (UDP sur le port 514)
echo "Configuration de Rsyslog pour l'écoute réseau..."

cat <<EOL > /etc/rsyslog.d/10-remote.conf
# Activation de l'écoute UDP sur le port 514
module(load="imudp")
input(type="imudp" port="514")

# Stockage des logs entrants
$template RemoteLogs,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"
*.* ?RemoteLogs
& stop
EOL

# Création du dossier pour les logs distants
mkdir -p /var/log/remote
chown -R syslog:adm /var/log/remote

# Rechargement de Rsyslog
systemctl restart rsyslog
systemctl enable rsyslog

# Configuration de la rotation des logs
echo "Configuration de la rotation des logs..."

cat <<EOL > /etc/logrotate.d/rsyslog-remote
/var/log/remote/*/*.log {
    daily
    rotate 14
    compress
    missingok
    notifempty
    sharedscripts
    postrotate
        systemctl reload rsyslog > /dev/null
    endscript
}
EOL

# Vérification du service
systemctl status rsyslog --no-pager

# Finalisation
echo "Installation et configuration de Rsyslog terminées !"
echo "Ce serveur écoute les logs sur UDP : 514"
echo "Les logs distants seront stockés dans : /var/log/remote/"
