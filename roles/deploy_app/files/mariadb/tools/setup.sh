#!/bin/bash
service mariadb start

mariadb -e "CREATE DATABASE IF NOT EXISTS $db_name;"
mariadb -e "CREATE USER IF NOT EXISTS '$db_user'@'%' IDENTIFIED BY '$db_pass';"
mariadb -e "GRANT ALL PRIVILEGES ON $db_name.* TO '$db_user'@'%';"
mariadb -e "FLUSH PRIVILEGES;"
sed -i "s/bind-address/#bind-address/g" /etc/mysql/mariadb.conf.d/50-server.cnf

service mariadb stop

mysqld