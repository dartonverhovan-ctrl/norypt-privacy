#!/bin/sh
# NORYPT Privacy — one-command SSH installer
# Usage: sh install.sh  (run on the router via SSH)
set -e

REPO="https://raw.githubusercontent.com/dartonverhovan-ctrl/norypt-privacy/main"
MODULES=/etc/norypt
WWW=/www/norypt
CGI=/www/cgi-bin

echo "=== NORYPT Privacy Installer v1.0.0 ==="

if [ -f /etc/glversion ]; then
  # shellcheck disable=SC2312
  echo "Detected GL-iNet firmware v$(cat /etc/glversion)"
else
  echo "Detected vanilla OpenWrt"
fi

# Install missing dependencies (coreutils-shuf required for unbiased random selection)
_opkg_install() {
  opkg update >/dev/null 2>&1 || true
  opkg install "$1" || echo "WARNING: failed to install $1 — install manually if needed"
}
for dep in uqmi bash coreutils-shuf; do
  if ! opkg list-installed 2>/dev/null | grep -q "^${dep} "; then
    echo "Installing: ${dep}"
    _opkg_install "${dep}"
  fi
done

# Avoid 'local' keyword — not POSIX; use positional parameters directly
get() {
  echo "  $2"
  curl -fsSL "${REPO}/$1" -o "$2"
  chmod "${3:-644}" "$2"
}

mkdir -p "${MODULES}" "${WWW}" "${CGI}"

echo "Installing modules..."
for f in detect_fw.sh luhn.sh random_mac.sh imei-random.sh \
          mac-random.sh wan-mac.sh log-wipe.sh cellular.sh run.sh; do
  get "src/modules/${f}" "${MODULES}/${f}" 755
done

echo "Installing databases..."
for f in tac.db oui-wifi.db oui-wan.db; do
  get "src/db/${f}" "${MODULES}/${f}" 644
done

echo "Installing service files..."
get "src/init.d/norypt"          /etc/init.d/norypt            755
get "src/uci-defaults/99-norypt" /etc/uci-defaults/99-norypt   755
get "src/bin/norypt"             /usr/bin/norypt                755
get "src/cgi-bin/norypt.cgi"    "${CGI}/norypt.cgi"              755

echo "Installing web panel..."
for f in index.html style.css app.js; do
  get "src/www/${f}" "${WWW}/${f}" 644
done

if [ ! -f /etc/config/norypt ]; then
  get "src/config/norypt" /etc/config/norypt 644
fi

echo "Enabling service..."
/etc/init.d/norypt enable
/etc/init.d/norypt start

echo "Configuring uhttpd redirect for CSRF-injected panel..."
if uci show uhttpd >/dev/null 2>&1; then
  if ! uci show uhttpd 2>/dev/null | grep -q "norypt_redirect"; then
    uci add uhttpd redirect > /dev/null
    uci set uhttpd.@redirect[-1].name='norypt_redirect'
    uci set uhttpd.@redirect[-1].from='/norypt/'
    uci set uhttpd.@redirect[-1].to='/cgi-bin/norypt.cgi?action=serve_index'
    uci commit uhttpd
  fi
  /etc/init.d/uhttpd restart 2>/dev/null || true
fi

echo "Setting up sysupgrade persistence..."
if ! grep -q '/etc/norypt/' /etc/sysupgrade.conf 2>/dev/null; then
  cat >> /etc/sysupgrade.conf << 'EOF'
/etc/norypt/
/etc/config/norypt
/etc/init.d/norypt
/etc/uci-defaults/99-norypt
/usr/bin/norypt
/www/cgi-bin/norypt.cgi
/www/norypt/
EOF
fi

echo ""
echo "=== Done ==="
echo "Panel : http://192.168.8.1/norypt/"
echo "CLI   : norypt status"
