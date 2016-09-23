#!/usr/bin/env ash
# "/usr/sbin/lighttpd", "-D", "-f", "/etc/lighttpd/lighttpd.conf"
if [ ! -e ".stamp_migration" ]
  date > last_import.log
  /usr/local/bin/migration.sh
  touch .stamp_migration
fi
/usr/sbin/lighttpd -D -f /etc/lighttpd/lighttpd.conf

