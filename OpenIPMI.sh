#!/bin/bash

set -e

echo "Mise à jour du système..."
apt update && apt upgrade -y

echo "Installation d'OpenIPMI et IPMITool..."
apt install -y openipmi ipmitool

echo "Activation et démarrage du service OpenIPMI..."
systemctl enable openipmi
systemctl start openipmi

echo "Vérification de l'état du service OpenIPMI..."
systemctl status openipmi --no-pager

echo "Test de communication avec l'interface IPMI..."
ipmitool mc info

echo "Installation terminée !"
