#!/usr/bin/env bats
load 'test_helper'

CLI="$BATS_TEST_DIRNAME/../src/bin/norypt"
export NORYPT_TEST=1

@test "version exits 0 and shows 1.0.0" {
  run bash "$CLI" version
  assert_success
  assert_output --partial "1.0.0"
}
@test "help shows randomize and status" {
  run bash "$CLI" help
  assert_output --partial "randomize"
  assert_output --partial "status"
}
@test "no args shows Usage" {
  run bash "$CLI"
  assert_output --partial "Usage"
}
@test "unknown command exits 1" {
  run bash "$CLI" foobar
  assert_failure
}

@test "config show exits 0 with mocked uci" {
  NORYPT_MODULES_DIR="$BATS_TEST_DIRNAME/../src/modules" \
    run bash "$CLI" config show
  assert_success
}

@test "wipe-logs exits 0 with NORYPT_TEST=1" {
  NORYPT_MODULES_DIR="$BATS_TEST_DIRNAME/../src/modules" \
  NORYPT_VARLOG="$(mktemp -d)" \
  NORYPT_TMPLOG="$(mktemp -d)" \
    run bash "$CLI" wipe-logs
  assert_success
}

@test "randomize imei exits 0 in test mode" {
  NORYPT_MODULES_DIR="$BATS_TEST_DIRNAME/../src/modules" \
  TAC_DB="$BATS_TEST_DIRNAME/../src/db/tac.db" \
  MODEM_PORT="/dev/null" \
    run bash "$CLI" randomize imei
  assert_success
}
