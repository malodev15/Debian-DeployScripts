#!/bin/bash

set -e

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation de HAProxy
echo "Installation de HAProxy..."
apt install -y haproxy

# Sauvegarde de la configuration existante
echo "Sauvegarde de la configuration actuelle..."
cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.bak

# Configuration de base de HAProxy
echo "Création d'une configuration de base..."
cat <<EOL > /etc/haproxy/haproxy.cfg
# Configuration globale
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

# Paramètres par défaut
defaults
    log global
    option httplog
    option dontlognull
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    retries 3

# Statistiques accessibles via l'interface web
listen stats
    bind *:9000
    stats enable
    stats uri /stats
    stats realm Haproxy\ Statistics
    stats auth admin:haproxy

# Backend HTTP
frontend http_front
    bind *:80
    default_backend http_back

backend http_back
    balance roundrobin
    server web1 192.168.1.101:80 check
    server web2 192.168.1.102:80 check
EOL

# Activation et démarrage de HAProxy
echo "Activation et démarrage de HAProxy..."
systemctl enable haproxy
systemctl restart haproxy

# Vérification de l'état de HAProxy
echo "Vérification de l'installation..."
systemctl status haproxy --no-pager

# Finalisation
echo "Installation de HAProxy terminée !"
echo "Accédez au tableau de bord : http://$(hostname -I | awk '{print $1}'):9000"
echo "Identifiants : admin / haproxy"
