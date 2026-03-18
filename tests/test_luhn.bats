#!/usr/bin/env bats
load 'test_helper'

setup() { source "$BATS_TEST_DIRNAME/../src/modules/luhn.sh"; }

@test "luhn_digit is defined" {
  declare -f luhn_digit > /dev/null
}
@test "known-answer: prefix 35394110123456 gives check digit 2" {
  result=$(luhn_digit "35394110123456")
  assert_equal "$result" "2"
}
@test "single digit 0 produces check 0" {
  result=$(luhn_digit "0")
  assert_equal "$result" "0"
}
@test "output is a single digit 0-9" {
  result=$(luhn_digit "35394110123456")
  [[ "$result" =~ ^[0-9]$ ]]
}
