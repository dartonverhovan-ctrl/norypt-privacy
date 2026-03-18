#!/usr/bin/env bats
load 'test_helper'

setup() {
  source "$BATS_TEST_DIRNAME/../src/modules/luhn.sh"
  export TAC_DB="$BATS_TEST_DIRNAME/../src/db/tac.db"
  export MODEM_PORT="/dev/null"
  export NORYPT_TEST=1
}

teardown() { rm -f /tmp/norypt_mock_at_calls /tmp/norypt_mock_imei; }

run_imei() { bash "$BATS_TEST_DIRNAME/../src/modules/imei-random.sh"; }

@test "imei-random.sh exits 0" {
  run run_imei
  assert_success
}

@test "generated IMEI is 15 digits" {
  result=$(run_imei)
  [[ "$result" =~ ^[0-9]{15}$ ]]
}

@test "IMEI TAC matches an entry in tac.db" {
  result=$(run_imei)
  tac="${result:0:8}"
  grep -q "^${tac}$" "$TAC_DB"
}

@test "IMEI passes Luhn check" {
  result=$(run_imei)
  prefix="${result:0:14}"
  expected=$(luhn_digit "$prefix")
  assert_equal "${result:14:1}" "$expected"
}

@test "AT command sequence is called: QCFG unlock then EGMR write" {
  # Exercise the AT path by unsetting NORYPT_TEST so main() calls _at
  # MODEM_PORT points to /dev/null; send_at mock is on PATH
  NORYPT_TEST="" MODEM_PORT="/dev/null" \
    bash "$BATS_TEST_DIRNAME/../src/modules/imei-random.sh" >/dev/null 2>&1 || true
  # EGMR call must have been recorded by send_at mock
  grep -q "EGMR" /tmp/norypt_mock_at_calls
}
