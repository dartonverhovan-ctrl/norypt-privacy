#!/usr/bin/env bats
load 'test_helper'

setup() {
  source "$BATS_TEST_DIRNAME/../src/modules/random_mac.sh"
  export WIFI_DB="$BATS_TEST_DIRNAME/../src/db/oui-wifi.db"
  export WAN_DB="$BATS_TEST_DIRNAME/../src/db/oui-wan.db"
}

@test "random_mac_from_db is defined" {
  declare -f random_mac_from_db > /dev/null
}
@test "output is valid MAC address format XX:XX:XX:XX:XX:XX" {
  result=$(random_mac_from_db "$WIFI_DB")
  [[ "$result" =~ ^[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}$ ]]
}
@test "OUI prefix comes from the database" {
  result=$(random_mac_from_db "$WIFI_DB")
  oui="${result%:*:*:*}"
  grep -q "^${oui}" "$WIFI_DB"
}
@test "first byte has bit0=0 and bit1=0 (globally unique unicast)" {
  result=$(random_mac_from_db "$WIFI_DB")
  first="${result%%:*}"
  val=$(( 16#$first ))
  [ $(( val & 0x03 )) -eq 0 ]
}
@test "works with WAN database too" {
  result=$(random_mac_from_db "$WAN_DB")
  [[ "$result" =~ ^[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}:[0-9A-F]{2}$ ]]
}
