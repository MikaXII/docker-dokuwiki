#!/bin/bash
# "/usr/sbin/lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"
if [ ! -e ".stamp_migration" ]; then
  date > last_import.log
  /usr/local/bin/migration.sh
  touch .stamp_migration
  echo Migration_OK
fi
/usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf

