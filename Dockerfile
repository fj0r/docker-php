FROM nnurphy/deployment

ARG PHP_VERSION=7.2
ENV PHP_PGKS \
        php${PHP_VERSION} \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-json \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bcmath \
        php-xdebug

RUN set -eux \
  ; curl -sL https://packages.sury.org/php/apt.gpg | apt-key add - \
  ; echo "deb https://packages.sury.org/php/ buster main"  \
        | tee /etc/apt/sources.list.d/php.list \
  ; apt-get update \
  ; apt-get install -y --no-install-recommends $PHP_PGKS \
  ; apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

RUN set -eux \
  ; ln -sf /usr/sbin/php-fpm${PHP_VERSION} /usr/sbin/php-fpm \
  ; sed -e 's!^.*\(date.timezone =\).*$!\1 Asia/Shanghai!' \
        -e 's!^.*\(track_errors =\).*$!\1 Off!' \
        #-e 's!^\(error_reporting =.*\)$!\1 \& ~E_WARNING!' \
        -i /etc/php/${PHP_VERSION}/fpm/php.ini \
  ; sed -e 's!.*\(daemonize =\).*!\1 no!' \
        -i /etc/php/${PHP_VERSION}/fpm/php-fpm.conf \
  ; sed -e 's!\(listen =\).*!\1 /var/run/php/php-fpm.sock!' \
        -e 's!.*\(clear_env =\).*$!\1 no!' \
        -i /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf \
  ; mkdir -p /var/run/php \
  ; { \
      echo 'xdebug.remote_log="/tmp/xdebug.log"' ; \
      echo 'xdebug.remote_enable=on' ; \
      echo 'xdebug.remote_autostart=on' ; \
      echo 'xdebug.remote_port=9001' ; \
      echo 'xdebug.idekey=XDEBUG_ECLIPSE' ; \
    } >> /etc/php/${PHP_VERSION}/mods-available/xdebug.ini

COPY docker-nginx-default /etc/nginx/conf.d/default.conf
COPY services.d/php-fpm /etc/services.d/php-fpm