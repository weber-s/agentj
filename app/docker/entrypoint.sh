#!/bin/sh
set -e

# Configure opendkim
sed -i "s/\$MAIL_HOSTNAME/$MAIL_HOSTNAME/g" /etc/opendkim/TrustedHosts
sed -i "s/\$IPV4_NETWORK/$IPV4_NETWORK/g" /etc/opendkim/TrustedHosts
touch /etc/opendkim/DomainsList
touch /etc/opendkim/KeyTable
touch /etc/opendkim/SigningTable
addgroup www-data opendkim
if [ ! -d /etc/opendkim/keys ]
then
    mkdir /etc/opendkim/keys
fi
chgrp -R opendkim /etc/opendkim
chmod -R g+w /etc/opendkim

# Generate APP_SECRET (required for CSRF token)
MYAPPSECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
# Generate token for encryption
MY_TOKEN_ENC_IV=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)
MY_TOKEN_ENC_SALT=$(openssl rand -base64 32)

sed -i "s|\$MYAPPSECRET|$MYAPPSECRET|g" /var/www/agentj/.env
sed -i "s|\$MY_TOKEN_ENC_IV|$MY_TOKEN_ENC_IV|g" /var/www/agentj/.env
sed -i "s|\$MY_TOKEN_ENC_SALT|$MY_TOKEN_ENC_SALT|g" /var/www/agentj/.env
sed -i "s|\$DB_NAME|$DB_NAME|g" /var/www/agentj/.env
sed -i "s|\$DB_USER|$DB_USER|g" /var/www/agentj/.env
sed -i "s|\$DB_PASSWORD|$DB_PASSWORD|g" /var/www/agentj/.env
sed -i "s|\$MAIL_HOSTNAME|$MAIL_HOSTNAME|g" /var/www/agentj/.env
sed -i "s|\$MAIL_DOMAINNAME|$MAIL_DOMAINNAME|g" /var/www/agentj/.env

echo "Installing assets"
cd /var/www/agentj && sudo -u www-data php8 bin/console assets:install

echo "Create database if not exists and update schemas"
cd /var/www/agentj && sudo -u www-data php8 bin/console doctrine:database:create --if-not-exists
cd /var/www/agentj && sudo -u www-data php8 bin/console doctrine:migration:migrate

echo "Create or update super admin user"
cd /var/www/agentj && php8 bin/console agentj:create-super-admin $SUPER_ADMIN_USERNAME $SUPER_ADMIN_password

# Allow web server user to write Symphony logs
rm -rf /var/www/agentj/var/cache
chown -R www-data:www-data /var/www/agentj/var
find /var/www/agentj/public -type d -exec chmod go+rwx {} \;
# Allow web server user to purge old virus and spam mails
addgroup -g 101 amavis && adduser www-data amavis && chmod -R g+w /tmp/amavis/quarantine

echo "Installing crontabs"
if [ ! -d /var/log/agentj ]
then
    mkdir /var/log/agentj && chown -R www-data /var/log/agentj
fi

crond

exec "$@"
