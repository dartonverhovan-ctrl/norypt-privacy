#!/usr/bin/env bats
load 'test_helper'

setup() {
  source "$BATS_TEST_DIRNAME/../src/modules/random_mac.sh"
  export WAN_DB="$BATS_TEST_DIRNAME/../src/db/oui-wan.db"
  export NORYPT_TEST=1 IF_WAN=eth0
  rm -f /tmp/norypt_mock_{ip,uci}_calls /tmp/norypt_mock_ifupdown_calls
}
teardown() { rm -f /tmp/norypt_mock_{ip,uci}_calls /tmp/norypt_mock_ifupdown_calls; }

@test "exits 0 in boot mode" {
  run bash "$BATS_TEST_DIRNAME/../src/modules/wan-mac.sh" --boot
  assert_success
}
@test "exits 0 in runtime mode" {
  run bash "$BATS_TEST_DIRNAME/../src/modules/wan-mac.sh"
  assert_success
}
@test "boot mode does NOT call ifdown/ifup" {
  bash "$BATS_TEST_DIRNAME/../src/modules/wan-mac.sh" --boot
  ! grep -q "wan" /tmp/norypt_mock_ifupdown_calls 2>/dev/null
}
@test "runtime mode calls ifdown and ifup wan" {
  bash "$BATS_TEST_DIRNAME/../src/modules/wan-mac.sh"
  grep -q "wan" /tmp/norypt_mock_ifupdown_calls
}
@test "uci commit network called" {
  bash "$BATS_TEST_DIRNAME/../src/modules/wan-mac.sh" --boot
  grep -q "commit network" /tmp/norypt_mock_uci_calls
}
