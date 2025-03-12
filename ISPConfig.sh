#!/bin/bash

set -e

# Dépendance : Vérifier et exécuter Web.sh si nécessaire
web_script="/root/Web.sh"

if ! command -v apache2 &> /dev/null || ! command -v php &> /dev/null || ! command -v mysql &> /dev/null; then
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
apt install -y curl wget git unzip net-tools bash-completion haveged

# Téléchargement et extraction d'ISPConfig
echo "Téléchargement d'ISPConfig..."
cd /usr/local/src
wget -O ispconfig.tar.gz https://www.ispconfig.org/downloads/ISPConfig-3-stable.tar.gz
tar -xvzf ispconfig.tar.gz
cd ispconfig3_install/install/

# Création du fichier de réponse automatique
echo "Création du fichier de réponse automatique..."
cat <<EOF > /root/ispconfig_auto.ini
[install]
language = en
install_mode = standard
hostname = $(hostname -f)
mysql_root_password = your_mysql_root_password
mysql_ispconfig_user = ispconfig
mysql_ispconfig_password = your_ispconfig_password
mysql_master_slave_setup = no
mysql_master_host = 
mysql_master_root_password = 
mysql_master_ispconfig_user = 
mysql_master_ispconfig_password = 
configure_mail = y
configure_jailkit = y
configure_ftp = y
configure_dns = y
configure_apache = y
configure_nginx = n
configure_firewall = y
configure_database = y
create_ssl_cert = y
ssl_cert_country = FR
ssl_cert_state = IDF
ssl_cert_locality = Paris
ssl_cert_organisation = MyCompany
ssl_cert_organisation_unit = IT
ssl_cert_common_name = $(hostname -f)
ssl_cert_email = admin@$(hostname -d)
EOF

# Installation automatique d'ISPConfig
echo "Installation d'ISPConfig en mode automatique..."
php -q install.php --autoinstall=/root/ispconfig_auto.ini

# Configuration du Virtual Host sécurisé pour ISPConfig
echo "Configuration d'Apache pour ISPConfig..."
cat <<EOF > /etc/apache2/sites-available/ispconfig.vhost
<VirtualHost *:8080>
    ServerAdmin admin@$(hostname -d)
    DocumentRoot /usr/local/ispconfig/interface/web/
    ServerName $(hostname -I | awk '{print $1}')

    <Directory /usr/local/ispconfig/interface/web>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/ispconfig_error.log
    CustomLog \${APACHE_LOG_DIR}/ispconfig_access.log combined
</VirtualHost>
EOF

# Activation du site et rechargement d'Apache
a2ensite ispconfig.vhost
systemctl reload apache2

# Finalisation
echo "Installation terminée avec succès !"
echo "📌 Accédez à l'interface ISPConfig : http://$(hostname -I | awk '{print $1}'):8080"
echo "🗝️ Identifiants :"
echo "   - Utilisateur : admin"
echo "   - Mot de passe : défini pendant l'installation"
