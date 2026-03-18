#!/usr/bin/env bats
load 'test_helper'

setup() {
  source "$BATS_TEST_DIRNAME/../src/modules/random_mac.sh"
  export WIFI_DB="$BATS_TEST_DIRNAME/../src/db/oui-wifi.db"
  export NORYPT_TEST=1 IF_WIFI_2G=wlan0 IF_WIFI_5G=wlan1
  rm -f /tmp/norypt_mock_{ip,uci,wifi}_calls
}
teardown() { rm -f /tmp/norypt_mock_{ip,uci,wifi}_calls; }

@test "mac-random.sh exits 0" {
  run bash "$BATS_TEST_DIRNAME/../src/modules/mac-random.sh"
  assert_success
}
@test "ip link called for wlan0" {
  bash "$BATS_TEST_DIRNAME/../src/modules/mac-random.sh"
  grep -q "wlan0" /tmp/norypt_mock_ip_calls
}
@test "ip link called for wlan1" {
  bash "$BATS_TEST_DIRNAME/../src/modules/mac-random.sh"
  grep -q "wlan1" /tmp/norypt_mock_ip_calls
}
@test "uci commit wireless called" {
  bash "$BATS_TEST_DIRNAME/../src/modules/mac-random.sh"
  grep -q "commit wireless" /tmp/norypt_mock_uci_calls
}
@test "wifi down and wifi up both called" {
  bash "$BATS_TEST_DIRNAME/../src/modules/mac-random.sh"
  grep -q "down" /tmp/norypt_mock_wifi_calls
  grep -q "up" /tmp/norypt_mock_wifi_calls
}
