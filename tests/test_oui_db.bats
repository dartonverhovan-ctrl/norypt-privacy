#!/usr/bin/env bats
load 'test_helper'

WIFI_DB="$BATS_TEST_DIRNAME/../src/db/oui-wifi.db"
WAN_DB="$BATS_TEST_DIRNAME/../src/db/oui-wan.db"

_check_oui_db() {
  local db="$1"
  [ -f "$db" ] && [ -s "$db" ]
}

_check_format() {
  local db="$1"
  while IFS= read -r line; do
    [[ "$line" =~ ^[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}\ .+$ ]]
  done < "$db"
}

_check_unicast_global() {
  local db="$1"
  while IFS= read -r line; do
    local oui="${line%% *}"
    local first_byte="${oui%%:*}"
    local val=$(( 16#$first_byte ))
    # bit0=0 (unicast), bit1=0 (globally unique)
    [ $(( val & 0x03 )) -eq 0 ]
  done < "$db"
}

@test "oui-wifi.db exists and is non-empty" {
  _check_oui_db "$WIFI_DB"
}
@test "oui-wan.db exists and is non-empty" {
  _check_oui_db "$WAN_DB"
}
@test "oui-wifi.db has correct format (AA:BB:CC VendorName)" {
  _check_format "$WIFI_DB"
}
@test "oui-wan.db has correct format (AA:BB:CC VendorName)" {
  _check_format "$WAN_DB"
}
@test "oui-wifi.db has at least 20 entries" {
  count=$(wc -l < "$WIFI_DB")
  [ "$count" -ge 20 ]
}
@test "oui-wan.db has at least 20 entries" {
  count=$(wc -l < "$WAN_DB")
  [ "$count" -ge 20 ]
}
@test "oui-wifi.db OUIs are globally unique (bit0=0, bit1=0)" {
  _check_unicast_global "$WIFI_DB"
}
@test "oui-wan.db OUIs are globally unique (bit0=0, bit1=0)" {
  _check_unicast_global "$WAN_DB"
}
