#!/bin/bash

set -eor schools

# Mise à jour du système
echo "Mise à jour du système..."
apt update && apt upgrade -y

# Installation de Dovecot et de ses modules
echo "Installation de Dovecot..."
apt install -y dovecot-core dovecot-imapd dovecot-pop3d dovecot-mysql

# Configuration de Dovecot
DOVECOT_CONF="/etc/dovecot/dovecot.conf"
echo "Configuration de Dovecot..."

cat <<EOF > $DOVECOT_CONF
!include_try /usr/share/dovecot/protocols.d/*.protocol
protocols = imap pop3
mail_location = maildir:~/Maildir
listen = *
ssl = no
service auth {
    unix_listener /var/spool/postfix/private/auth {
        mode = 0660
        user = postfix
        group = postfix
    }
}
EOF

# Activation et démarrage du service Dovecot
echo "Activation et démarrage de Dovecot..."
systemctl enable dovecot
systemctl restart dovecot

# Finalisation
echo "Installation et configuration de Dovecot terminées !"
echo "IMAP et POP3 sont désormais disponibles sur le serveur."
echo "Vérifiez la configuration avec : doveadm status mail"
