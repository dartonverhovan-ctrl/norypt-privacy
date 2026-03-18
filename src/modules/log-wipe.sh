#!/usr/bin/env bash
set -euo pipefail

VARLOG="${NORYPT_VARLOG:-/var/log}"
TMPLOG="${NORYPT_TMPLOG:-/tmp/log}"

_log() { logger -t norypt "wipe: $*" 2>/dev/null || true; }

_wipe_dir() {
  local dir="$1"
  [[ -d "${dir}" ]] && find "${dir}" -maxdepth 1 -type f -delete
}

main() {
  _wipe_dir "${VARLOG}"
  _wipe_dir "${TMPLOG}"
  rm -f /tmp/wpa_ctrl_* 2>/dev/null || true
  if [[ -d /var/run/hostapd ]]; then rm -f /var/run/hostapd/* 2>/dev/null || true; fi
  rm -f /tmp/.uci/* 2>/dev/null || true
  if [[ -z "${NORYPT_TEST:-}" ]]; then
    rm -f /var/lib/misc/dnsmasq.* 2>/dev/null || true
    # Flush in-memory syslog ring buffer — correct OpenWrt method
    # NORYPT_LOG_RESTART allows test override of this path
    "${NORYPT_LOG_RESTART:-/etc/init.d/log}" restart 2>/dev/null || true
  fi
  _log "log wipe complete"
}

main "$@"
