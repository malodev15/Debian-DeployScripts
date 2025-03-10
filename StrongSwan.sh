#!/bin/bash

set -e

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation de StrongSwan et des utilitaires
echo "Installation de StrongSwan..."
apt install -y strongswan strongswan-pki libcharon-extra-plugins libcharon-standard-plugins strongswan-swanctl

# Création des dossiers pour les certificats
mkdir -p /etc/ipsec.d/{certs,private,acerts}

# Génération d'une autorité de certification (CA)
echo "Génération de l'Autorité de Certification (CA)..."
ipsec pki --gen --outform pem > /etc/ipsec.d/private/ca-key.pem
ipsec pki --self --ca --lifetime 3650 --in /etc/ipsec.d/private/ca-key.pem --type rsa --dn "C=FR, O=Entreprise, CN=VPN Root CA" --outform pem > /etc/ipsec.d/certs/ca-cert.pem

# Génération du certificat serveur
echo "Génération du certificat du serveur..."
ipsec pki --gen --outform pem > /etc/ipsec.d/private/server-key.pem
ipsec pki --pub --in /etc/ipsec.d/private/server-key.pem | ipsec pki --issue --lifetime 1825 --cacert /etc/ipsec.d/certs/ca-cert.pem --cakey /etc/ipsec.d/private/ca-key.pem --dn "C=FR, O=Entreprise, CN=$(hostname -I | awk '{print $1}')" --san="$(hostname -I | awk '{print $1}')" --flag serverAuth --flag ikeIntermediate --outform pem > /etc/ipsec.d/certs/server-cert.pem

# Configuration d'IPsec (StrongSwan)
echo "Configuration de StrongSwan..."

cat <<EOL > /etc/ipsec.conf
config setup
    charondebug="ike 2, knl 2, cfg 2"

conn %default
    keyexchange=ikev2
    ike=aes256-sha256-modp2048
    esp=aes256-sha256
    dpdaction=clear
    dpddelay=300s
    rekey=no
    left=%any
    leftsubnet=0.0.0.0/0
    leftcert=server-cert.pem
    right=%any
    rightdns=8.8.8.8
    rightsourceip=10.10.10.0/24

conn vpn
    auto=start
EOL

# Configuration des identifiants
echo "Configuration des identifiants VPN..."

cat <<EOL > /etc/ipsec.secrets
: RSA "server-key.pem"
EOL

# Activation du service IPsec
echo "Activation et démarrage de StrongSwan..."
systemctl enable strongswan
systemctl restart strongswan

# Activation du transfert IP (NAT)
echo "Activation du transfert IP pour le routage..."
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# Configuration des règles iptables pour le NAT
echo "Configuration des règles iptables..."
iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE
iptables-save > /etc/iptables.rules

# Chargement automatique des règles au démarrage
cat <<EOL > /etc/network/if-up.d/iptables
#!/bin/bash
iptables-restore < /etc/iptables.rules
EOL

chmod +x /etc/network/if-up.d/iptables

# Finalisation
echo "Installation et configuration de StrongSwan terminées !"
echo "Adresse IP du serveur VPN : $(hostname -I | awk '{print $1}')"
echo "Les clients peuvent se connecter en utilisant IKEv2."
