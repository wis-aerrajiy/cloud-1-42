FROM debian:bullseye

RUN apt-get update

RUN apt-get install -y php7.4 php7.4-fpm php7.4-mysql

RUN apt-get install -y wget curl php-mysql php-redis mariadb-client redis

COPY ./tools/setup.sh /setup.sh

RUN chmod +x /setup.sh

EXPOSE 9000


CMD ["/setup.sh"]
