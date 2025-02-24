#!/bin/bash

set -e

# Variables personnalisables
db_name="roundcube"
db_user="roundcubeuser"
db_pass="roundcube_pass"
domain="mail.example.com"

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

# Configuration de la base de données pour Roundcube
echo "Création de la base de données Roundcube..."
mysql -e "CREATE DATABASE ${db_name} DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
mysql -e "GRANT ALL PRIVILEGES ON ${db_name}.* TO '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';"
mysql -e "FLUSH PRIVILEGES;"

# Téléchargement et installation de Roundcube
echo "Téléchargement de Roundcube..."
ROUND_VERSION="1.6.7"
wget https://github.com/roundcube/roundcubemail/releases/download/${ROUND_VERSION}/roundcubemail-${ROUND_VERSION}-complete.tar.gz

tar -xvzf roundcubemail-${ROUND_VERSION}-complete.tar.gz -C /var/www/
mv /var/www/roundcubemail-${ROUND_VERSION} /var/www/roundcube

# Configuration d'Apache pour Roundcube
echo "Configuration d'Apache pour Roundcube..."
cat <<EOL > /etc/apache2/sites-available/roundcube.conf
<VirtualHost *:80>
    ServerName ${domain}
    DocumentRoot /var/www/roundcube

    <Directory /var/www/roundcube>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/roundcube_error.log
    CustomLog \${APACHE_LOG_DIR}/roundcube_access.log combined
</VirtualHost>
EOL

a2ensite roundcube.conf
a2enmod rewrite
systemctl reload apache2

# Configuration de Roundcube
echo "Configuration de Roundcube..."
cp /var/www/roundcube/config/config.inc.php.sample /var/www/roundcube/config/config.inc.php

sed -i "s/\$config\['db_dsnw'\] = '.*';/\$config['db_dsnw'] = 'mysql:\/\/${db_user}:${db_pass}@localhost\/${db_name}';/" /var/www/roundcube/config/config.inc.php

# Initialisation de la base de données Roundcube
mysql ${db_name} < /var/www/roundcube/SQL/mysql.initial.sql

# Permissions
echo "Ajustement des permissions..."
chown -R www-data:www-data /var/www/roundcube

# Finalisation
echo "Installation de Roundcube terminée !"
echo "Accédez à : http://${domain}"