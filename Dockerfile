FROM php:8.1-apache

# Install php libs
RUN set -ex; \
    \
    aptMarkList="$(apt-mark showmanual)"; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        libjpeg-dev \
        libpng-dev \
        libmagickwand-dev \
        libwebp-dev \
        libfreetype6-dev \
        libzip-dev \
        libxml2-dev \
        libc-client-dev \
        libkrb5-dev \
        libldap2-dev \
        libzmq5-dev \
        zlib1g-dev \
    ; \
    \
# Install php-zmq
    cd /usr; \
    curl -fSL https://github.com/zeromq/php-zmq/archive/ee5fbc693f07b2d6f0d9fd748f131be82310f386.tar.gz -o php-zmq.tar.gz; \
    tar -zxf php-zmq.tar.gz; \
    cd php-zmq*; \
    phpize && ./configure; \
    make; \
    make install; \
    cd .. && rm -rf php-zmq*; \
# END: Install php-zmq
    \
    pecl install imagick-3.6.0; \
    debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)"; \
    docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch"; \
    docker-php-ext-configure gd --with-jpeg --with-freetype --with-webp; \
    PHP_OPENSSL=yes docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
    \
    docker-php-ext-install \
        pdo_mysql \
        zip \
        gd \
        imap \
        ldap \
        exif \
        pcntl \
        posix \
        bcmath \
    ; \
    docker-php-ext-enable \
        zmq \
        imagick \
    ; \
    \
    rm -r /tmp/pear; \
    \
# reset a list of apt-mark
    apt-mark auto '.*' > /dev/null; \
    apt-mark manual $aptMarkList; \
    ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
        | awk '/=>/ { print $3 }' \
        | sort -u \
        | xargs -r realpath | xargs -r dpkg-query --search \
        | cut -d: -f1 \
        | sort -u \
        | xargs -rt apt-mark manual; \
    \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false

# Install required libs
RUN set -ex; \
    apt-get install -y --no-install-recommends \
        unzip \
        libldap-common \
    ; \
    rm -rf /var/lib/apt/lists/*

# php.ini
RUN { \
	echo 'expose_php = Off'; \
	echo 'display_errors = Off'; \
	echo 'display_startup_errors = Off'; \
	echo 'log_errors = On'; \
	echo 'memory_limit=256M'; \
	echo 'max_execution_time=180'; \
	echo 'max_input_time=180'; \
	echo 'post_max_size=30M'; \
	echo 'upload_max_filesize=30M'; \
	echo 'date.timezone=UTC'; \
} > ${PHP_INI_DIR}/conf.d/espocrm.ini

RUN a2enmod rewrite;

ENV ESPOCRM_VERSION 7.5.4
ENV ESPOCRM_SHA256 8e18b15d1e657ba6939dd6012d4283de3c4eb24a994eb189820077e5a85518a3

WORKDIR /var/www/html

RUN set -ex;
COPY . /usr/src/espocrm
RUN set -ex; \
    chown -R www-data:www-data /usr/src/espocrm

COPY ./docker-*.sh  /usr/local/bin/
RUN ["chmod", "+x", "docker-entrypoint.sh"]
RUN ["chmod", "+x", "docker-daemon.sh"]

ENTRYPOINT [ "docker-entrypoint.sh" ]

CMD ["apache2-foreground"]
