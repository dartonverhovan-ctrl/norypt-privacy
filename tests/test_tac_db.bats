#!/usr/bin/env bats
load 'test_helper'

TAC_DB="$BATS_TEST_DIRNAME/../src/db/tac.db"

@test "tac.db exists and is non-empty" {
  [ -f "$TAC_DB" ]
  [ -s "$TAC_DB" ]
}
@test "every TAC is exactly 8 digits" {
  while IFS= read -r line; do
    [[ "$line" =~ ^[0-9]{8}$ ]]
  done < "$TAC_DB"
}
@test "tac.db has at least 150 entries" {
  count=$(wc -l < "$TAC_DB")
  [ "$count" -ge 150 ]
}
@test "no duplicate TACs" {
  dupes=$(sort "$TAC_DB" | uniq -d | wc -l)
  [ "$dupes" -eq 0 ]
}
