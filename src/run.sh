#!/bin/bash

/usr/local/bin/init.sh

exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf -l /var/log/supervisor/supervisor.log
