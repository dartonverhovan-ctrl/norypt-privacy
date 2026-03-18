#!/bin/sh
set -e
echo "=== NORYPT Privacy Uninstaller ==="
/etc/init.d/norypt stop    2>/dev/null || true
/etc/init.d/norypt disable 2>/dev/null || true
rm -rf /etc/norypt /www/norypt
rm -f /etc/init.d/norypt /usr/bin/norypt /www/cgi-bin/norypt.cgi
rm -f /etc/config/norypt /etc/uci-defaults/99-norypt
_norypt_sec=$(uci show uhttpd 2>/dev/null | grep "\.name='norypt_redirect'" | cut -d. -f1-2)
if [ -n "${_norypt_sec}" ]; then
  uci delete "${_norypt_sec}"
  uci commit uhttpd
  /etc/init.d/uhttpd restart 2>/dev/null || true
fi
if [ -f /etc/sysupgrade.conf ]; then
  sed -i '/norypt/d' /etc/sysupgrade.conf
fi
echo "NORYPT Privacy removed."
