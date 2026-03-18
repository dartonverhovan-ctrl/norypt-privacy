#!/usr/bin/env bash
set -euo pipefail

MODULES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG=norypt

# Default "0" — config file ships with all features on; absent config = safe off
_cfg() { uci -q get "${CONFIG}.settings.$1" 2>/dev/null || echo "0"; }

# Respect enabled gate whether called from init.d or CLI
_enabled=$(_cfg enabled)
if [[ "${_enabled}" != "1" ]]; then exit 0; fi

SETTLE_DELAY=$(_cfg settle_delay)
if [[ -z "${SETTLE_DELAY}" ]]; then SETTLE_DELAY=3; fi

# shellcheck source=/dev/null
source "${MODULES_DIR}/detect_fw.sh"
export IF_WAN IF_WIFI_2G IF_WIFI_5G IF_WWAN IF_CDC MODEM_PORT

_cfg_wipe_logs=$(_cfg wipe_logs)
if [[ "${_cfg_wipe_logs}" = "1" ]]; then bash "${MODULES_DIR}/log-wipe.sh"; fi
_cfg_randomize_imei=$(_cfg randomize_imei)
if [[ "${_cfg_randomize_imei}" = "1" ]]; then bash "${MODULES_DIR}/imei-random.sh"; fi
_cfg_randomize_bssid=$(_cfg randomize_bssid)
if [[ "${_cfg_randomize_bssid}" = "1" ]]; then bash "${MODULES_DIR}/mac-random.sh"; fi
_cfg_randomize_wan=$(_cfg randomize_wan)
if [[ "${_cfg_randomize_wan}" = "1" ]]; then bash "${MODULES_DIR}/wan-mac.sh" --boot; fi

sleep "${SETTLE_DELAY}"

bash "${MODULES_DIR}/cellular.sh"
