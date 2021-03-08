FROM alpine:latest

# ADD https://dl.bintray.com/php-alpine/key/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub
# RUN apk --update add ca-certificates && \
#   echo "https://dl.bintray.com/php-alpine/v3.11/php-7.4" >> /etc/apk/repositories

RUN apk update && apk upgrade && \
    apk add apk-tools grep build-base tar re2c make file curl openrc openssl wget git \
    ssmtp python3 py-pip libxpm-dev libxml2-dev curl-dev freetype-dev socat mysql-client \
    bash bc mysql memcached \
    apache2-ssl apache2-webdav apache2-error apache2-utils apache2-icons apache2-ctl \
    ca-certificates apache2-doc apache2-ldap libressl netcat-openbsd certbot goaccess fail2ban openssh

# php part
RUN apk update && apk add \
        php php-bz2 php-json php-common php-fpm php-cgi php-apache2 php-dom \
        php-apache2 php-tokenizer php-pdo php-sqlite3 \
        php-imap php-ctype php-bcmath php-calendar php-sockets php-simplexml php-ftp \
        php-mbstring php-openssl php-gd php-curl php-pdo php-posix php-xmlrpc php-xmlreader php-fileinfo \
        php-pear php-tokenizer php-pdo php-xsl php-mysqlnd \
        php-opcache php-gd php-gettext php-json php-iconv php-imap php-pgsql \
        php-apache2 php-ctype php-bcmath php-calendar php-dom php-sockets \
        php-ftp php-bz2 php-simplexml composer php-shmop php-fpm php-soap \
        php-intl php-json php-gd php-curl php7-memcached php7-imagick php7-mcrypt php-zlib \
        php-pdo_mysql php-mysqli php-mysqlnd php-zip php-xml php-xmlwriter php-xmlrpc php-xmlreader php-simplexml \
        php-posix sudo php-pcntl php-fileinfo php-cli php7-pecl-yaml php7-dev php7-memcached php7-redis \
        php7-sqlite3 \
        composer

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
RUN apk add python3 python3-dev apache2-mod-wsgi apache2-mod-wsgi-doc apache2-dev cython
RUN pip3 install --upgrade pip
# RUN pip3 install django plotly pandas TwitterAPI PyMySQL sqlalchemy mod_wsgi mod_wsgi-httpd virtualenv
# RUN pip3 install django virtualenv
RUN apk add py3-django py3-virtualenv py3-twitter py3-mysqlclient py3-sqlalchemy apache2-mod-wsgi

# Alpine SDK
RUN apk add alpine-sdk build-base autoconf automake libtool libexttextcat libexttextcat-dev pkgconfig libtool m4

# Nodejs
RUN apk add nodejs npm

# PDF manipulation part
RUN apk add wkhtmltopdf poppler-utils libxml2 libxslt libxml2-dev libxslt-dev xvfb xvfb-run docker
# ADD https://github.com/pdf2htmlEX/pdf2htmlEX/releases/download/continuous/pdf2htmlEX-0.18.8.rc1-master-20200630-alpine-3.12.0-x86_64.tar.gz /usr/local/src/pdf2htmlex.tar.gz
ADD https://github.com/pdf2htmlEX/pdf2htmlEX/releases/download/v0.18.8.rc1/pdf2htmlEX-0.18.8.rc1-master-20200630-alpine-3.12.0-x86_64.tar.gz /usr/local/src/pdf2htmlex.tar.gz
RUN cd / && tar -xzvf /usr/local/src/pdf2htmlex.tar.gz

# NLP Manipulation part
# https://github.com/LanguageMachines/
# RUN pip3 install folia folia-tools

# vsftpd part
RUN apk add vsftpd linux-pam linux-pam-dev
RUN mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.orig
ADD ./src/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf
ADD ./src/vsftpd/supervisor.vsftpd.conf /etc/supervisor/conf.d/vsftpd.conf.disabled
ADD ./src/ssh/supervisor.ssh.conf /etc/supervisor/conf.d/ssh.conf.disabled
# curl -sSL https://github.com/tiwe-de/libpam-pwdfile/archive/v1.0.tar.gz | tar xz --strip 1; \
COPY ./src/vsftpd/v1.0.tar.gz /usr/local/src/v1.0.tar.gz

# PANDOC package
# RUN apk add cabal ghc
# RUN cabal update
# RUN echo "installdir: /usr/local/bin/" >> /root/.cabal/config
# RUN cabal install pandoc --global --prefix=/usr/local/
## END PANDOC package

RUN cd /usr/local/src && tar -xzvf /usr/local/src/v1.0.tar.gz && cd /usr/local/src/libpam-pwdfile-1.0; \
    make && make install; \
    rm -rf /usr/local/src/pam_pwdfile-1.0

# COPY ./src/vsftpd/v1.0.tar.gz /usr/local/src/v1.0.tar.gz
# RUN cd /usr/local/src && tar -xzvf /usr/local/src/v1.0.tar.gz && cd /usr/local/src/libpam-pwdfile-1.0; \
#    make && make install; \
#    rm -rf /usr/local/src/pam_pwdfile-1.0

CMD ["/usr/local/bin/run.sh"]
