FROM alpine:latest

ADD https://dl.bintray.com/php-alpine/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub
RUN apk --update add ca-certificates && \
    echo "https://dl.bintray.com/php-alpine/v3.11/php-7.4" >> /etc/apk/repositories

RUN apk update && apk upgrade && \
    apk add apk-tools grep build-base tar re2c make file php-apache2 curl php-cli openrc openssl wget git \
    php-json php-phar php-openssl ssmtp python py-pip libxpm-dev libxml2-dev curl-dev freetype-dev socat \
   	libjpeg-turbo-dev libpng-dev libmcrypt-dev libwebp-dev icu-dev imap-dev bash php7-sqlite3 bc \
    php7-pear php7-tokenizer php7-pdo php7-oauth php7-xsl php7-imagick php7-mysqlnd \
    php7-dev php7-doc php7-opcache php7-gd php7-gettext php7-json php7-iconv php7-imap php7-pgsql \
    php7-apache2 php7-ctype php7-bcmath php7-calendar php7-dom php7-sockets php7-event php7-memcached \
    php7-ftp php7-bz2 php7-simplexml composer php7-shmop php7-fpm \
    apache2-ssl apache2-webdav php7-apache2 apache2-error apache2-utils apache2-icons apache2-ctl \
    ca-certificates apache2-doc apache2-ldap libressl php7-openssl php7-mbstring php7-apcu php7-intl php7-mcrypt php7-json php7-gd php7-curl \
    php7-pdo_mysql php7-mysqli php7-mysqlnd php7-pear-mdb2_driver_mysql memcached php7-zip php7-xml php7-xmlwriter php7-xmlrpc php7-xmlreader php7-simplexml \
    php7-posix sudo php7-pcntl php7-fileinfo php7-apcu mysql-client netcat-openbsd certbot goaccess fail2ban openssh \
    && rm -rf /var/cache/apk/*

ADD ./src/fail2ban-wrapper.sh /usr/local/bin/fail2ban-wrapper.sh
ADD ./src/supervisord.conf /etc/supervisor/supervisord.conf
ADD ./src/apache2/*.template /etc/apache2/sites.conf.d/
ADD ./src/init.sh /usr/local/bin/init.sh
ADD ./src/run.sh /usr/local/bin/run.sh
ADD ./src/cert.sh /usr/local/bin/cert.sh

RUN pip install supervisor && \
    mkdir -p /run/apache2/ && \
    mkdir -p /var/log/supervisor && \
    chmod 755 /usr/local/bin/*.sh

# python part
# https://www.digitalocean.com/community/tutorials/how-to-serve-django-applications-with-apache-and-mod_wsgi-on-ubuntu-14-04
RUN apk add python3 python3-dev apache2-mod-wsgi apache2-mod-wsgi-doc apache2-dev
RUN pip3 install --upgrade pip
RUN pip3 install django plotly pandas TwitterAPI PyMySQL sqlalchemy mod_wsgi mod_wsgi-httpd virtualenv

# vsftpd part
RUN apk add vsftpd linux-pam linux-pam-dev
RUN mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.orig
ADD ./src/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf
ADD ./src/vsftpd/supervisor.vsftpd.conf /etc/supervisor/conf.d/vsftpd.conf.disabled
ADD ./src/ssh/supervisor.ssh.conf /etc/supervisor/conf.d/ssh.conf.disabled
RUN cd /usr/local/src && curl -sSL https://github.com/tiwe-de/libpam-pwdfile/archive/v1.0.tar.gz | tar xz --strip 1; \
    make && make install; \
    rm -rf /usr/local/src/pam_pwdfile-1.0

# COPY ./src/vsftpd/v1.0.tar.gz /usr/local/src/v1.0.tar.gz
# RUN cd /usr/local/src && tar -xzvf /usr/local/src/v1.0.tar.gz && cd /usr/local/src/libpam-pwdfile-1.0; \
#    make && make install; \
#    rm -rf /usr/local/src/pam_pwdfile-1.0

CMD ["/usr/local/bin/run.sh"]
