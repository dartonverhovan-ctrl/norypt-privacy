#!/usr/bin/env bats
load 'test_helper'

setup() {
  export NORYPT_TEST=1 IF_WWAN=wwan0
  rm -f /tmp/norypt_mock_ifupdown_calls
}

@test "cellular.sh exits 0" {
  run bash "$BATS_TEST_DIRNAME/../src/modules/cellular.sh"
  assert_success
}
@test "ifdown wwan is called" {
  bash "$BATS_TEST_DIRNAME/../src/modules/cellular.sh"
  grep -q "mock ifdown: wwan" /tmp/norypt_mock_ifupdown_calls
}
@test "ifup wwan is called" {
  bash "$BATS_TEST_DIRNAME/../src/modules/cellular.sh"
  grep -q "mock ifup: wwan" /tmp/norypt_mock_ifupdown_calls
}
