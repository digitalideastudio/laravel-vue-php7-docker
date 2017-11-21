FROM ubuntu:16.04
MAINTAINER Serhii Matrunchyk <serhii@digitalidea.studio>


### Install basic software utilities
####################################

RUN apt-get update && apt-get install -y \
    software-properties-common

RUN apt-get update && apt-get install -y \
    python-software-properties


### Add a php7.1 repo & Install necessary dependencies
######################################################

# Install locales
RUN apt-get update && apt-get install -y \
    locales curl
RUN locale-gen en_US.UTF-8 && export LANG=en_US.UTF-8
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
RUN curl -sS https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 46C2130DFD2497F5 A040830F7FAC5991 1397BC53640DB551
RUN curl -sL https://deb.nodesource.com/setup_7.x | bash

RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    python-software-properties \
    openssh-client \
    curl \
    ca-certificates \
    wget \
    apache2 \
    curl \
    git \
    netcat \
    mcrypt \
    php7.1 \
    php7.1-cli \
    php7.1-mbstring \
    php7.1-mongodb \
    php7.1-mysql \
    php7.1-xml \
    php7.1-gmp \
    php7.1-zip \
    php7.1-gd \
    php7.1-mcrypt \
    php7.1-dom \
    php7.1-xdebug \
    php-curl \
    php-imagick \
    php-redis \
    bzip2 \
    supervisor \
    google-chrome-stable

# Disable XDebug on the CLI
RUN phpdismod -s cli xdebug

## Install codesniffer
RUN wget https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar
RUN chmod +x phpcs.phar
RUN mv phpcs.phar /usr/local/bin/phpcs

## Install mess detector
RUN wget http://static.phpmd.org/php/latest/phpmd.phar
RUN chmod +x phpmd.phar
RUN mv phpmd.phar /usr/local/bin/phpmd

## Install PHPUnit
RUN wget https://phar.phpunit.de/phpunit-5.7.phar
RUN chmod +x phpunit-5.7.phar
RUN mv phpunit-5.7.phar /usr/local/bin/phpunit


### Install composer & Configure apache
#######################################

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
RUN a2enmod rewrite


### Final server prep
#####################

CMD until nc -z -w90 $DB_HOST $DB_PORT; do sleep 3; echo "Waiting for mysql..."; done \
    && composer install \
    && supervisord -c /etc/supervisor/conf.d/laravel-worker.conf \
    && php artisan migrate \
    && php artisan db:seed \
    && php artisan batch:updateBrokeragesList \
    && /usr/sbin/apache2ctl -k start \
    && tail -f /var/log/apache2/access.log /var/log/apache2/error.log /var/www/sites/api/storage/logs/laravel.log
