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

# Installation d'OpenLDAP et des utilitaires
echo "Installation d'OpenLDAP..."
DEBIAN_FRONTEND=noninteractive apt install -y slapd ldap-utils

# Configuration automatique de slapd
echo "Configuration de slapd..."
ldap_domain="example.local"
ldap_org="ExampleOrg"
ldap_admin_pass="MotDePasseAdmin"

dpkg-reconfigure -f noninteractive slapd <<EOF
$ldap_domain
$ldap_org
5
7
$ldap_admin_pass
$ldap_admin_pass
no
EOF

# Création d'une unité organisationnelle et d'un utilisateur de test
echo "Ajout d'une OU et d'un utilisateur de test..."
cat > /tmp/base.ldif <<EOL
dn: ou=users,dc=example,dc=local
objectClass: organizationalUnit
ou: users

# Utilisateur de test
dn: cn=testuser,ou=users,dc=example,dc=local
objectClass: inetOrgPerson
cn: testuser
sn: user
userPassword: $(slappasswd -s testpass)
EOL

ldapadd -x -D "cn=admin,dc=example,dc=local" -w "$ldap_admin_pass" -f /tmp/base.ldif

# Activation et démarrage d'OpenLDAP
echo "Activation et démarrage du service slapd..."
systemctl enable slapd
systemctl restart slapd

# Finalisation
echo "Installation et configuration d'OpenLDAP terminées !"
echo "Accès : ldap://$(hostname -I | awk '{print $1}')"
echo "Base DN : dc=example,dc=local"
echo "Admin : cn=admin,dc=example,dc=local / $ldap_admin_pass"
