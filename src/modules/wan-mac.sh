#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/random_mac.sh"

WAN_DB="${WAN_DB:-${SCRIPT_DIR}/../db/oui-wan.db}"
IF_WAN="${IF_WAN:-eth0}"
BOOT_MODE=0
[[ "${1:-}" = "--boot" ]] && BOOT_MODE=1

_log() { logger -t norypt "wan: $*" 2>/dev/null || echo "norypt wan: $*" >&2; }

main() {
  local mac
  mac=$(random_mac_from_db "${WAN_DB}")

  ip link set dev "${IF_WAN}" down
  ip link set dev "${IF_WAN}" address "${mac}"
  ip link set dev "${IF_WAN}" up
  uci set "network.wan.macaddr=${mac}"
  uci commit network

  # Boot: network daemon brings eth0 up after init — no restart needed.
  # Runtime: restart WAN only — full network restart would drop wwan0.
  if [[ "${BOOT_MODE}" -eq 0 ]]; then
    ifdown wan 2>/dev/null || true
    ifup wan
  fi

  _log "eth0=${mac} (boot=${BOOT_MODE})"
}

main "$@"
