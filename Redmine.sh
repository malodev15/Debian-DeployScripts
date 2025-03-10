#!/bin/bash

set -e

# Chemin vers le script Web.sh
web_script="/root/Web.sh"

# Vérification et exécution du script Web.sh si nécessaire
if ! command -v apache2 &>/dev/null || ! command -v mysql &>/dev/null || ! command -v php &>/dev/null; then
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
echo "Installation des dépendances pour Redmine..."
apt install -y ruby ruby-dev libapache2-mod-passenger zlib1g-dev imagemagick libmagickwand-dev

# Création de la base de données Redmine
DB_NAME="redmine"
DB_USER="redmineuser"
DB_PASS="MotDePasseFort123"

echo "Création de la base de données MariaDB pour Redmine..."
mysql -u root <<EOF
CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

# Installation de Redmine
REDMINE_DIR="/var/www/redmine"

if [ ! -d "$REDMINE_DIR" ]; then
    echo "Téléchargement et installation de Redmine..."
    wget https://www.redmine.org/releases/redmine-5.1.0.tar.gz
    tar -xzf redmine-5.1.0.tar.gz -C /var/www
    mv /var/www/redmine-5.1.0 $REDMINE_DIR
else
    echo "Redmine est déjà installé."
fi

# Configuration de Redmine
echo "Configuration de Redmine..."

cat <<EOL > $REDMINE_DIR/config/database.yml
production:
  adapter: mysql2
  database: $DB_NAME
  host: localhost
  username: $DB_USER
  password: "$DB_PASS"
  encoding: utf8mb4
EOL

cd $REDMINE_DIR

# Installation des dépendances Ruby (via Bundler)
echo "Installation des gemmes Ruby pour Redmine..."
apt install -y bundler
gem install bundler
bundle install --without development test

# Génération de la clé secrète
echo "Génération de la clé secrète..."
bundle exec rake generate_secret_token

# Migration de la base de données
echo "Migration de la base de données Redmine..."
RAILS_ENV=production bundle exec rake db:migrate

# Configuration d'Apache avec Passenger pour Redmine
echo "Configuration d'Apache pour Redmine..."

cat <<EOL > /etc/apache2/sites-available/redmine.conf
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot $REDMINE_DIR/public
    ServerName $(hostname -I | awk '{print $1}')
    <Directory "$REDMINE_DIR/public">
        Require all granted
        Options -MultiViews
    </Directory>
    PassengerEnabled on
    PassengerAppRoot $REDMINE_DIR
</VirtualHost>
EOL

a2enmod passenger
a2ensite redmine
systemctl restart apache2

# Finalisation
echo "Installation de Redmine terminée !"
echo "Accédez à Redmine : http://$(hostname -I | awk '{print $1}')/redmine"
echo "Identifiants par défaut : admin / admin"
