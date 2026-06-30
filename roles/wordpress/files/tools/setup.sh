#!/bin/bash
set_permissions() {
    find /var/www/wordpress -type d -exec chmod 757 {} \;
    find /var/www/wordpress -type f -exec chmod 757 {} \;
    chown -R www-data:www-data /var/www/wordpress
}

while ! mysql -h "${db_host}" -P "${db_port}" -u "${db_user}" -p"${db_pass}" -e "SELECT 1" "${db_name}" 2>/dev/null; do
    echo "Waiting for database connection..."
    sleep 1
done

sed -i "s/listen = \/run\/php\/php7.4-fpm.sock/listen = 9000/" "/etc/php/7.4/fpm/pool.d/www.conf"

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

cd /var/www/wordpress
mkdir -p /run/php

if [ -f wp-config.php ]; then
    echo "Wordpress configuration already done"
else
    wp core download --allow-root
    wp config create --dbname="${db_name}" --dbuser="${db_user}" --dbpass="${db_pass}" --dbhost="${db_host}" --allow-root
    wp core install \
        --url="${domain_name}" \
        --title="${site_title}" \
        --admin_user="${admin_user}" \
        --admin_password="${admin_pass}" \
        --admin_email="${admin_mail}" \
        --skip-email \
        --allow-root
    wp user create "${user_user}" "${user_mail}" \
        --role=author \
        --user_pass="${user_pass}" \
        --allow-root
    wp theme install newsmash --activate --allow-root
fi

set_permissions
/usr/sbin/php-fpm7.4 -F