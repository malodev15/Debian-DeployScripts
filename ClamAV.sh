#!/bin/bash

set -e

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation de ClamAV et de ses utilitaires
echo "Installation de ClamAV..."
apt install -y clamav clamav-daemon

# Arrêt du service ClamAV pendant la mise à jour
systemctl stop clamav-freshclam

# Mise à jour de la base de données des virus
echo "Mise à jour de la base de données des virus..."
freshclam

# Redémarrage du service de mise à jour automatique
systemctl enable clamav-freshclam
systemctl start clamav-freshclam

# Activation de l'analyse en temps réel (On-Access Scanning)
echo "Activation de l'analyse en temps réel..."
systemctl enable clamav-daemon
systemctl start clamav-daemon

# Configuration des analyses automatiques (via cron)
echo "Planification des analyses quotidiennes..."

cat <<EOL > /etc/cron.daily/clamav-scan
#!/bin/bash

LOG_FILE="/var/log/clamav/scan.log"
SCAN_DIR="/"

echo "Début de l'analyse : \$(date)" >> \$LOG_FILE
clamscan -r --bell --log=\$LOG_FILE \$SCAN_DIR
echo "Fin de l'analyse : \$(date)" >> \$LOG_FILE
EOL

chmod +x /etc/cron.daily/clamav-scan

# Finalisation
echo "Installation de ClamAV terminée !"
echo "Les analyses sont programmées quotidiennement."
echo "Consultez les logs : /var/log/clamav/scan.log"
