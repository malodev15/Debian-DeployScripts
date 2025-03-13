#!/bin/bash

set -e

# Chemin vers le script Web.sh
web_script="/root/Web.sh"

# Vérification des services Apache, MariaDB et PHP
if ! command -v apache2 &> /dev/null || ! command -v php &> /dev/null; then
    echo "📢 Apache2, MariaDB ou PHP non détecté. Exécution de Web.sh..."
    if [ -f "$web_script" ]; then
        bash "$web_script"
    else
        echo "❌ Erreur : $web_script introuvable."
        exit 1
    fi
else
    echo "✅ Services Web déjà installés."
fi

# Mise à jour du système
echo "🔄 Mise à jour du système..."
apt update && apt upgrade -y

# Installation de Subversion (SVN)
echo "📦 Installation de Subversion (SVN)..."
apt install -y subversion apache2 libapache2-mod-svn

# Création d'un dépôt SVN par défaut
repo_path="/var/svn/repos"
if [ ! -d "$repo_path" ]; then
    echo "📁 Création du dépôt SVN par défaut..."
    mkdir -p $repo_path
    svnadmin create $repo_path
    chown -R www-data:www-data $repo_path
else
    echo "✅ Le dépôt SVN existe déjà : $repo_path"
fi

# Configuration d'Apache pour SVN
echo "🔧 Configuration d'Apache pour SVN..."
svn_conf="/etc/apache2/mods-available/dav_svn.conf"
cat <<EOF > $svn_conf
<Location /svn>
    DAV svn
    SVNParentPath $repo_path
    AuthType Basic
    AuthName "SVN Repository"
    AuthUserFile /etc/apache2/dav_svn.passwd
    Require valid-user
</Location>
EOF

# Création d'un utilisateur SVN par défaut
if [ ! -f "/etc/apache2/dav_svn.passwd" ]; then
    echo "👤 Création d'un utilisateur SVN (user: admin)..."
    htpasswd -cb /etc/apache2/dav_svn.passwd admin admin
else
    echo "✅ Fichier de mot de passe SVN déjà existant."
fi

# Installation de WebSVN
echo "📦 Installation de WebSVN..."
apt install -y websvn

# Configuration de WebSVN
websvn_conf="/etc/websvn/config.php"
if [ -f "$websvn_conf" ]; then
    sed -i "s|\$config->addRepository('file://',.*| \$config->addRepository('My Repo', 'file://$repo_path');|" $websvn_conf
fi

# Activation des modules Apache et redémarrage
a2enmod dav dav_svn authz_svn
systemctl restart apache2

# Finalisation
echo "✅ Installation terminée !"
echo "- Accès au dépôt SVN : http://$(hostname -I | awk '{print $1}')/svn"
echo "- Interface WebSVN : http://$(hostname -I | awk '{print $1}')/websvn"
