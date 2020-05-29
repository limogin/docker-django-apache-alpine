#!/bin/bash

# Apache Setup
cp /etc/apache2/httpd.conf /etc/apache2/httpd.conf.backup
cd /etc/apache2/sites.conf.d/
mkdir -p /var/www/html
echo "IncludeOptional /etc/apache2/sites.conf.d/*.conf" >> /etc/apache2/httpd.conf
sed -ri -e "s/#LoadModule include_module/LoadModule include_module/" /etc/apache2/httpd.conf
sed -ri -e "s/#LoadModule cgid_module/LoadModule cgid_module/" /etc/apache2/httpd.conf
sed -ri -e "s/#LoadModule cgi_module/LoadModule cgi_module/" /etc/apache2/httpd.conf
# Define virtualhosts

for i in `seq 1 30`
do
  Q="SITE$i"
  eval "SITENDX=\${$Q}"
  if [ "$SITENDX" ];
  	then
  	  echo "setting virtualhost $SITENDX .. "
  	  cp /etc/apache2/sites.conf.d/virtualhost.template ${SITENDX}.conf
  	  sed -ri -e "s/SERVERNAME/${SITENDX}/g" /etc/apache2/sites.conf.d/${SITENDX}.conf
      sed -ri -e "s/SERVERALIAS/www.${SITENDX}/g" /etc/apache2/sites.conf.d/${SITENDX}.conf
  	  [ -d /var/www/html/${SITENDX} ] || mkdir -p /var/www/html/${SITENDX}
  	  [ -d /var/www/html/${SITENDX}/www ] || mkdir -p /var/www/html/${SITENDX}/www
      [ -d /var/www/html/${SITENDX}/tasks ] || mkdir -p /var/www/html/${SITENDX}/tasks
      [ -d /var/www/html/${SITENDX}/data ] || mkdir -p /var/www/html/${SITENDX}/data
      [ -d /var/www/html/${SITENDX}/log ] || mkdir -p /var/www/html/${SITENDX}/log
      if [ ! -d /var/www/html/${SITENDX}/certs ]; then
       mkdir -p /var/www/html/${SITENDX}/certs
       openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /var/www/html/${SITENDX}/certs/${SITENDX}.key -out /var/www/html/${SITENDX}/certs/${SITENDX}.pem -subj "/C=ES/ST=Spain/L=${SITENDX}/O=Dis/CN=${SITENDX}"
      fi

      # if [ "$SITE" == "$SITENDX" ];
      #  then
      #    sed -ri -e "s/SERVERALIAS/www.${SITENDX} \*/" /etc/apache2/sites.conf.d/${SITENDX}.conf
      #  else
      #    sed -ri -e "s/SERVERALIAS/www.${SITENDX}/"   /etc/apache2/sites.conf.d/${SITENDX}.conf
      # fi
  fi
done


cd /etc/apache2
sed -ri -e "s/#ServerName/ServerName/" /etc/apache2/httpd.conf
sed -ri -e "s/ServerName.*/ServerName ${SITE}/" /etc/apache2/httpd.conf
sed -ri -e "s#DocumentRoot.*#DocumentRoot /var/www/html/${SITE}/www#" /etc/apache2/httpd.conf
sed -ri -e "s/#LoadModule rewrite/LoadModule rewrite/" /etc/apache2/httpd.conf
sed -ri -e "s/#LoadModule deflate_module/LoadModule deflate_module/" /etc/apache2/httpd.conf

# Setup basic php.ini
sed -ri -e "s/upload_max_filesize =.*/upload_max_filesize = 256M/" /etc/php7/php.ini
sed -ri -e "s/short_open_tag =.*/short_open_tag = On/" /etc/php7/php.ini
sed -ri -e "s/memory_limit =.*/memory_limit = 1024M/" /etc/php7/php.ini
sed -ri -e "s/max_input_time =.*/max_input_time = 120/" /etc/php7/php.ini
sed -ri -e "s/max_input_time =.*/max_input_vars = 10000/" /etc/php7/php.ini
sed -ri -e "s/post_max_size =.*/post_max_size = 256M/" /etc/php7/php.ini
sed -ri -e "s/display_errors =.*/display_errors = Off/" /etc/php7/php.ini
sed -ri -e "s/html_errors =.*/html_errors = Off/" /etc/php7/php.ini
sed -ri -e "s/max_execution_time =.*/max_execution_time = 60/" /etc/php7/php.ini

if [ "$DOCKERENV" == "prod" ]; then

 echo "ServerSignature Off" >> /etc/apache2/apache2.conf
 echo "ServerTokens Prod" >> /etc/apache2/apache2.conf
 echo "TraceEnable Off" >> /etc/apache2/apache2.conf
 echo "LimitRequestBody 0" >> /etc/apache2/apache2.conf

 cp /etc/modsecurity/modsecurity.conf-recommended 	/etc/modsecurity/modsecurity.conf
 sed -ri -e "s/SecRuleEngine DetectionOnly/SecRuleEngine On/" /etc/modsecurity/modsecurity.conf
 sed -ri -e "s/SecResponseBodyAccess On/SecResponseBodyAccess Off/" /etc/modsecurity/modsecurity.conf
 sed -ri -e "s/SecRequestBodyLimit .*/SecRequestBodyLimit 131072000/" /etc/modsecurity/modsecurity.conf
 sed -ri -e "s/SecRequestBodyNoFilesLimit .*/SecRequestBodyNoFilesLimit 131072000/" /etc/modsecurity/modsecurity.conf
 sed -ri -e "s/SecRequestBodyInMemoryLimit .*/SecRequestBodyInMemoryLimit 131072000/" /etc/modsecurity/modsecurity.conf

fi

env | grep MYSQL > /etc/environment

openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/private/ssl-cert-snakeoil.key -out /etc/ssl/certs/ssl-cert-snakeoil.pem -subj "/C=ES/ST=Spain/L=fpr/O=Dis/CN=fpr"

if [ "$APACHE_RUN_USER" ]; then

 sed -ri -e "s/User apache/User ${APACHE_RUN_USER}/" /etc/apache2/httpd.conf
 sed -ri -e "s/Group apache/Group ${APACHE_RUN_USER}/" /etc/apache2/httpd.conf

 if [ ! $(getent passwd $APACHE_RUN_USER) ] ; then
  adduser --disabled-password --gecos "" ${APACHE_RUN_USER}
 fi
 chown -R ${APACHE_RUN_USER}.${APACHE_RUN_GROUP} /var/www

 # setup some apache Security
 mkdir -p /var/log/mod_evasive && chown ${APACHE_RUN_USER}:${APACHE_RUN_GROUP} /var/log/mod_evasive/

fi

adduser --disabled-password --gecos "" memcache

if [ ! -d /var/log/supervisord/ ]; then
 mkdir /var/log/supervisord/
fi

[ -d /etc/data.conf ] ||  mkdir /etc/data.conf

if [ ! -d /etc/data.conf/ssmtp ]; then
 mv /etc/ssmtp /etc/data.conf/ssmtp
 ln -s /etc/data.conf/ssmtp /etc/ssmtp
else
 mv /etc/ssmtp /etc/ssmtp.backup
 ln -s /etc/data.conf/ssmtp /etc/ssmtp
fi

if [ ! -d /etc/data.conf/apache2 ]; then
 mv /etc/apache2 /etc/data.conf/apache2
 ln -s /etc/data.conf/apache2 /etc/apache2
else
 mv /etc/apache2 /etc/apache2.backup
 ln -s /etc/data.conf/apache2 /etc/apache2
fi

if [ ! -d /etc/data.conf/fail2ban ]; then
 cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.conf.backup
 sed -ri -e "s/#ignoreip/ignoreip/" /etc/fail2ban/jail.conf
 sed -ri -e "s/bantime .*/bantime = 604800/" /etc/fail2ban/jail.conf
 mv /etc/fail2ban /etc/data.conf/fail2ban
 ln -s /etc/data.conf/fail2ban /etc/fail2ban
else
 mv /etc/fail2ban /etc/fail2ban.backup
 ln -s /etc/data.conf/fail2ban /etc/fail2ban
fi

if [ "$CRONTAB_DAILY" ]; then
 [ -d /var/spool/cron/crontabs/ ] || mkdir /var/spool/cron/crontabs/
 echo "23 0 * * *  ${CRONTAB_DAILY}" >> /var/spool/cron/crontabs/root
fi

if [ "$CRONTAB_MONTH" ]; then
 [ -d /var/spool/cron/crontabs/ ] || mkdir /var/spool/cron/crontabs/
 echo "0 0 1 *  ${CRONTAB_MONTH}" >> /var/spool/cron/crontabs/root
fi

touch /var/log/supervisord/cron-stderr.log
touch /var/log/supervisord/cron-stdout.log
touch /var/log/supervisord/memcached-stderr.log
touch /var/log/supervisord/memcached-stdout.log
touch /var/log/supervisord/httpd-stderr.log
touch /var/log/supervisord/httpd-stdout.log

if [ -d /var/log/messages ]; then
  mkdir /var/log/messages
fi

if [ ! -d /var/data.log ]; then
 mv /var/log /var/data.log
 ln -s /var/data.log /var/log
else
 mv /var/log /var/log.backup
 ln -s /var/data.log /var/log
fi

if [ ! -d /etc/data.conf/supervisor ]; then
  mv /etc/supervisor /etc/data.conf/supervisor
  ln -s /etc/data.conf/supervisor /etc/supervisor
  [ -f /etc/supervisord.conf ] || rm -f /etc/supervisord.conf
  ln -s /etc/data.conf/supervisor/supervisord.conf /etc/supervisord.conf
else
  mv /etc/supervisor /etc/supervisor.backup
  ln -s /etc/data.conf/supervisor /etc/supervisor
  [ -f /etc/supervisord.conf ] || rm -f /etc/supervisord.conf
  ln -s /etc/data.conf/supervisor/supervisord.conf /etc/supervisord.conf
fi

if [ ! -d /etc/letsencrypt ]; then
 mkdir /etc/letsencrypt
fi

if [ ! -d /etc/data.conf/letsencrypt ]; then
 mv /etc/letsencrypt /etc/data.conf/letsencrypt
 ln -s /etc/data.conf/letsencrypt /etc/letsencrypt
else
 mv /etc/letsencrypt /etc/letsencrypt.backup
 ln -s /etc/data.conf/letsencrypt /etc/letsencrypt
fi

if [ ! -d /etc/data.conf/vsftpd ]; then
 mv /etc/vsftpd /etc/data.conf/vsftpd
 ln -s /etc/data.conf/vsftpd /etc/vsftpd
else
 mv /etc/vsftpd /etc/vsftpd.backup
 ln -s /etc/data.conf/vsftpd /etc/vsftpd
fi


if [ "$OPENSSH" ]; then
  echo "${APACHE_RUN_USER}:${SSH_PASSWORD}" | chpasswd
  sed -ie 's/#Port 22/Port 22/g' /etc/ssh/sshd_config
  sed -ri 's/#HostKey \/etc\/ssh\/ssh_host_key/HostKey \/etc\/ssh\/ssh_host_key/g' /etc/ssh/sshd_config
  sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_rsa_key/HostKey \/etc\/ssh\/ssh_host_rsa_key/g' /etc/ssh/sshd_config
  sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_dsa_key/HostKey \/etc\/ssh\/ssh_host_dsa_key/g' /etc/ssh/sshd_config
  sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ecdsa_key/HostKey \/etc\/ssh\/ssh_host_ecdsa_key/g' /etc/ssh/sshd_config
  sed -ir 's/#HostKey \/etc\/ssh\/ssh_host_ed25519_key/HostKey \/etc\/ssh\/ssh_host_ed25519_key/g' /etc/ssh/sshd_config
  if [ ! -f "/etc/ssh/ssh_host_key" ]; then
   /usr/bin/ssh-keygen -A
   ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_key
  fi

  if [ ! -d "/etc/supervisor/conf.d/ssh.conf" ]; then
   cp /etc/supervisor/conf.d/ssh.conf.disabled /etc/supervisor/conf.d/ssh.conf
  fi
fi


if [ "$VSFTPD" ]; then
  if [ ! -f "/etc/vsftpd/ftpd.passwd" ]; then
    htpasswd -b -d -c /etc/vsftpd/ftpd.passwd default.site default.pass
  fi

  if [ ! -d "/etc/supervisor/conf.d/vsftpd.conf" ]; then
   cp /etc/supervisor/conf.d/vsftpd.conf.disabled /etc/supervisor/conf.d/vsftpd.conf
  fi

  sed -ri -e "s/ftpuser/${APACHE_RUN_USER}/g" /etc/vsftpd/vsftpd.conf

  openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.key -out /etc/ssl/private/vsftpd.pem -subj "/C=ES/ST=Spain/L=vsftpd/O=Dis/CN=vsftpd"

  # mkdir /usr/local/src/pam_pwdfile && cd /usr/local/src/pam_pwdfile
  # curl -sSL https://github.com/tiwe-de/libpam-pwdfile/archive/v1.0.tar.gz | tar xz --strip 1
  # make && make install
  # rm -rf /usr/local/src/pam_pwdfile

  for i in `seq 1 30`
  do
    Q1="FTPPASS$i"
    eval "PASSNDX=\${$Q1}"
    Q2="SITE$i"
    eval "SITENDX=\${$Q2}"
    if [ "$PASSNDX" ]; then
    	  echo "setting password ${SITENDX} .. "
        # htpasswd -b /etc/vsftpd/ftpd.passwd ${SITENDX} ${PASSNDX}
        echo "${SITENDX}:$(openssl passwd -1 ${PASSNDX})" >> /etc/vsftpd/ftpd.passwd
    fi
  done

  chmod 600 /etc/vsftpd/ftpd.passwd

  echo "#%PAM-1.0
auth  required  pam_pwdfile.so  pwdfile=/etc/vsftpd/ftpd.passwd
account   required  pam_permit.so" > /etc/pam.d/vsftpd
fi
