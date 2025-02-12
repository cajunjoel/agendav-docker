FROM debian:bullseye

MAINTAINER Ruslan Nagimov <nagimov@outlook.com>

ENV AGENDAV_VERSION 2.2.0

ENV APACHE_RUN_USER=www-data
ENV APACHE_RUN_GROUP=www-data
ENV APACHE_LOG_DIR=/var/log/apache2
ENV APACHE_LOCK_DIR=/var/lock/apache2
ENV APACHE_PID_FILE=/var/run/apache2.pid
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm
ENV AGENDAV_DB_NAME=agendav_database
ENV AGENDAV_DB_USER=agendav_db_user
ENV AGENDAV_DB_PASSWORD=agendav_db_password
ENV AGENDAV_TIMEZONE=UTC

RUN apt-get update && \
    apt-get install -y apt-transport-https \
        ca-certificates \
        gnupg \
        wget && \
    wget https://packages.sury.org/php/apt.gpg && \
    apt-key add apt.gpg && \
    echo 'deb https://packages.sury.org/php/ bullseye main' >> /etc/apt/sources.list.d/php.list && \
    apt-get update && \
    apt-get -y install \
        apache2 \
        php7.4 \
        php7.4-xml && \
    apt-get install nano && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cd /tmp && \
    wget https://github.com/agendav/agendav/releases/download/$AGENDAV_VERSION/agendav-$AGENDAV_VERSION.tar.gz && \
    tar -xf agendav-$AGENDAV_VERSION.tar.gz -C /tmp && \
    mv /tmp/agendav-$AGENDAV_VERSION /var/www/agendav && \
    chown -R www-data:www-data /var/www/agendav/web/var

COPY agendav.conf /etc/apache2/sites-available/agendav.conf
COPY settings.php /var/www/agendav/web/config/settings.php
COPY run.sh /usr/local/bin/run.sh
COPY pre-env.sh /tmp/pre-env.sh

RUN chmod +x /tmp/pre-env.sh && \
    echo 'date.timezone = "AGENDAV_TIMEZONE"' >> /etc/php/7.4/cli/php.ini && \
    echo 'date.timezone = "AGENDAV_TIMEZONE"' >> /etc/php/7.4/apache2/php.ini && \
    echo 'magic_quotes_runtime = false' >> /etc/php/7.4/cli/php.ini && \
    echo 'magic_quotes_runtime = false' >> /etc/php/7.4/apache2/php.ini && \
    cd /etc/ssl/certs/ && \
    wget https://curl.haxx.se/ca/cacert.pem && \
    echo 'openssl.cafile = "/etc/ssl/certs/cacert.pem"' >> /etc/php/7.4/cli/php.ini && \
    echo 'openssl.cafile = "/etc/ssl/certs/cacert.pem"' >> /etc/php/7.4/apache2/php.ini && \
    echo 'curl.cainfo = "/etc/ssl/certs/cacert.pem"' >> /etc/php/7.4/cli/php.ini && \
    echo 'curl.cainfo = "/etc/ssl/certs/cacert.pem"' >> /etc/php/7.4/apache2/php.ini && \
    /bin/bash /tmp/pre-env.sh && \
    cd /var/www/agendav && \
    yes | php agendavcli migrations:migrate && \
    chmod +x /usr/local/bin/run.sh && \
    a2ensite agendav.conf && \
    a2dissite 000-default && \
    a2enmod rewrite && \
    a2enmod php7.4 && \
    service apache2 restart && \
    service apache2 stop

EXPOSE 80

ENTRYPOINT ["/usr/local/bin/run.sh"]

CMD ["apache2"]
