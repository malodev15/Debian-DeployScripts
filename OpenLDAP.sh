#!/bin/bash

set -e

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation des paquets OpenLDAP et utilitaires
echo "Installation d'OpenLDAP..."
apt install -y slapd ldap-utils

# Configuration automatisée d'OpenLDAP
echo "Configuration d'OpenLDAP..."
debconf-set-selections <<EOF
slapd slapd/internal/generated_adminpw password adminpassword
slapd slapd/internal/adminpw password adminpassword
slapd slapd/password2 password adminpassword
slapd slapd/password1 password adminpassword
slapd slapd/domain string example.com
slapd shared/organization string "Example Org"
slapd slapd/backend select MDB
slapd slapd/purge_database boolean true
slapd slapd/move_old_database boolean true
slapd slapd/allow_ldap_v2 boolean false
EOF

DEBIAN_FRONTEND=noninteractive apt reinstall -y slapd

# Vérification du service
echo "Vérification du service OpenLDAP..."
systemctl enable slapd
systemctl start slapd

# Création d'une structure LDAP de base
echo "Création de la structure de base..."
cat <<EOL > base.ldif
dn: ou=people,dc=example,dc=com
objectClass: organizationalUnit
ou: people

dn: ou=groups,dc=example,dc=com
objectClass: organizationalUnit
ou: groups

EOL

ldapadd -x -D cn=admin,dc=example,dc=com -w adminpassword -f base.ldif

# Informations finales
echo "Installation et configuration d'OpenLDAP terminées !"
echo "- Domaine : example.com"
echo "- Admin : cn=admin,dc=example,dc=com"
echo "- Mot de passe : adminpassword"
echo "N'oubliez pas de personnaliser le domaine et le mot de passe dans le script !"