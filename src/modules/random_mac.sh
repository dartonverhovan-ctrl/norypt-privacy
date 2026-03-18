#!/usr/bin/env bash
# random_mac.sh — MAC address generation from OUI database
# Source this file to use random_mac_from_db()
# Requires: shuf (coreutils-shuf), od

random_mac_from_db() {
  local db="$1"
  # shuf provides unbiased urandom-seeded line selection (coreutils-shuf dep)
  local oui
  # shellcheck disable=SC2312
  oui=$(shuf -n1 "${db}" | awk '{print $1}')
  # Generate 3 random NIC bytes from urandom
  local nic
  # shellcheck disable=SC2312
  nic=$(od -An -N3 -tx1 /dev/urandom | tr -d ' \n' | \
        sed 's/\(..\)\(..\)\(..\)/\1:\2:\3/' | tr '[:lower:]' '[:upper:]')
  # Ensure bit0=0 (unicast) and bit1=0 (globally unique) in first byte
  local first val
  first=$(echo "${oui}" | cut -d: -f1)
  val=$(( 16#${first} & 0xFC ))
  first=$(printf "%02X" "${val}")
  oui="${first}:$(echo "${oui}" | cut -d: -f2-3)"
  echo "${oui}:${nic}"
}
