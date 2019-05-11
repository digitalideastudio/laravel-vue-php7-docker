FROM ubuntu:16.04
MAINTAINER Serhii Matrunchyk <serhii@digitalidea.studio>

### Install basic software utilities
####################################

RUN apt-get update && apt-get install -y \
    software-properties-common

RUN apt-get update && apt-get install -y \
    python-software-properties

ENV APP_HOME /var/www/html

### Add a php7.2 repo & Install necessary dependencies
######################################################

# Install locales
RUN apt-get update && apt-get install -y \
    locales curl
RUN locale-gen en_US.UTF-8 && export LANG=en_US.UTF-8
RUN LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
RUN curl -sS https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 46C2130DFD2497F5 A040830F7FAC5991 1397BC53640DB551
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash
RUN echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

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
    php7.2 \
    php7.2-dev \
    php7.2-cli \
    php7.2-mbstring \
    php7.2-bcmath \
    php7.2-mongodb \
    php7.2-mysql \
    php7.2-xml \
    php7.2-gmp \
    php7.2-curl \
    php7.2-zip \
    php7.2-gd \
    php7.2-dom \
    php7.2-xdebug \
    php-curl \
    php-imagick \
    php-redis \
    bzip2 \
    supervisor \
    google-chrome-stable \
    nodejs \
    python-dev \
    xvfb \
    libgtk2.0-0 \
    libnotify-dev \
    libgconf-2-4 \
    libnss3 \
    libxss1 \
    libasound2 \
    rsync \
    libcairo2-dev \
    libjpeg-dev \
    libgif-dev \
    autoconf \
    vim \
    g++

# Install AWS Environment
RUN curl -O https://bootstrap.pypa.io/get-pip.py \
  && python get-pip.py \
  && pip install awscli

# Disable XDebug on the CLI
RUN phpdismod -s cli xdebug

# Add crontab file in the cron directory
ADD crontab /etc/cron.d/timeragent-cron
# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/timeragent-cron
# Apply cron job
RUN crontab /etc/cron.d/timeragent-cron

# Set PHP configurations
COPY php.ini /etc/php/7.2/apache2/php.ini
COPY xdebug.ini /etc/php/7.2/mods-available/xdebug.ini

## Install codesniffer
RUN wget https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar
RUN chmod +x phpcs.phar
RUN mv phpcs.phar /usr/local/bin/phpcs

## Install mess detector
# RUN wget http://static.phpmd.org/php/latest/phpmd.phar
# RUN chmod +x phpmd.phar
# RUN mv phpmd.phar /usr/local/bin/phpmd

## Install PHPUnit
RUN wget -O phpunit https://phar.phpunit.de/phpunit-7.phar
RUN chmod +x phpunit
RUN mv phpunit /usr/local/bin/phpunit


### Install composer & Configure apache
#######################################

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Enable Apache's rewrite module
RUN a2enmod rewrite
RUN a2ensite 000-default
RUN mkdir -p /var/www/html/public
RUN chown -R www-data: /var/www

RUN sed -i -e "s/html/html\/public/g" /etc/apache2/sites-enabled/000-default.conf
RUN echo '\n\
<Directory /var/www/>\n\
        Options Indexes FollowSymLinks\n\
        AllowOverride All\n\
        Require all granted\n\
</Directory>' >> /etc/apache2/conf-enabled/security.conf

EXPOSE 80

CMD apache2ctl -k start && tail -f /var/log/apache2/access.log /var/log/apache2/error.log
