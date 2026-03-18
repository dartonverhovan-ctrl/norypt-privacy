#!/usr/bin/env bats
load 'test_helper'

INIT="$BATS_TEST_DIRNAME/../src/init.d/norypt"

@test "init script is executable" {
  [ -x "$INIT" ]
}

@test "init script contains START=19" {
  grep -q "START=19" "$INIT"
}

@test "init script contains STOP=81" {
  grep -q "STOP=81" "$INIT"
}

@test "init script contains USE_PROCD=1" {
  grep -q "USE_PROCD=1" "$INIT"
}

@test "init script references run.sh" {
  grep -q "run.sh" "$INIT"
}
