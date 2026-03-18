#!/usr/bin/env bash
# detect_fw.sh — source this file to populate FW_VERSION, MODEM_PORT,
# IF_WAN, IF_WIFI_2G, IF_WIFI_5G, IF_WWAN, IF_CDC
#
# Accepts MOCK_RELEASE and MOCK_GLVERSION env vars for testing.

_glver="${MOCK_GLVERSION:-$(cat /etc/glversion 2>/dev/null)}"

if [[ -n "${_glver}" ]]; then
  _major=$(echo "${_glver}" | cut -d. -f1)
  _minor=$(echo "${_glver}" | cut -d. -f2)
  if [[ "${_major}" -ge 4 ]] && [[ "${_minor}" -ge 5 ]]; then
    FW_VERSION="v4.5+"
  else
    FW_VERSION="v4"
  fi
else
  FW_VERSION="vanilla"
fi

IF_WAN="${IF_WAN_OVERRIDE:-eth0}"
IF_WIFI_2G="${IF_WIFI_2G_OVERRIDE:-wlan0}"
IF_WIFI_5G="${IF_WIFI_5G_OVERRIDE:-wlan1}"
IF_WWAN="${IF_WWAN_OVERRIDE:-wwan0}"
IF_CDC="${IF_CDC_OVERRIDE:-/dev/cdc-wdm0}"

_resolve_modem_port() {
  for port in /dev/ttyUSB2 /dev/ttyUSB1 /dev/ttyUSB0 /dev/ttyUSB3; do
    [[ -e "${port}" ]] && echo "${port}" && return
  done
  echo ""
}
MODEM_PORT="${MODEM_PORT_OVERRIDE:-$(_resolve_modem_port)}"

export FW_VERSION IF_WAN IF_WIFI_2G IF_WIFI_5G IF_WWAN IF_CDC MODEM_PORT
