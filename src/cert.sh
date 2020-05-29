#!/bin/bash

for i in `seq 1 30`
do
  Q="SITE$i"
  eval "SITENDX=\${$Q}"
  if [ "$SITENDX" ];
  	then
  	  echo "setting certificate for $SITENDX .. "
      certbot certonly --standalone --preferred-challenges http -d ${SITENDX}

  	  cp /etc/apache2/sites.conf.d/${SITENDX}.conf  /etc/apache2/sites.conf.d/${SITENDX}.conf.backup
      sed -ri -e "s/SSLCertificateFile .*/SSLCertificateFile /etc/letsencrypt/live/${SITENDX}/cert.pem" /etc/apache2/sites.conf.d/${SITENDX}.conf
      sed -ri -e "s/SSLCertificateKeyFile .*/SSLCertificateKeyFile /etc/letsencrypt/live/${SITENDX}/privkey.pem" /etc/apache2/sites.conf.d/${SITENDX}.conf
      sed -ri -e "s/SSLCertificateChainFile .*/SSLCertificateChainFile /etc/letsencrypt/live/${SITENDX}/chain.pem" /etc/apache2/sites.conf.d/${SITENDX}.conf

  fi
done
