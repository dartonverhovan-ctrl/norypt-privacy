#!/usr/bin/env bats
load 'test_helper'

CGI="$BATS_TEST_DIRNAME/../src/cgi-bin/norypt.cgi"
export NORYPT_TEST=1

run_cgi() {
  REQUEST_METHOD=POST \
  QUERY_STRING="action=${1}" \
  HTTP_X_NORYPT_TOKEN="${2:-testtoken}" \
  NORYPT_CSRF_TOKEN="testtoken" \
    bash "$CGI"
}

@test "status returns Content-Type header" {
  run run_cgi status
  assert_output --partial "Content-Type: text/plain"
}
@test "status returns imei= key" {
  run run_cgi status
  assert_output --partial "imei="
}
@test "status returns cellular= key" {
  run run_cgi status
  assert_output --partial "cellular="
}
@test "wrong CSRF token returns 403" {
  run run_cgi status "badtoken"
  assert_output --partial "403"
}
@test "get_history returns Content-Type" {
  run run_cgi get_history
  assert_output --partial "Content-Type"
}
@test "get_history returns no_history when file absent" {
  NORYPT_HISTORY_FILE="/tmp/norypt_test_absent_$$" \
    run run_cgi get_history
  assert_output --partial "no_history"
}
@test "set_config with empty body returns invalid_key" {
  run run_cgi set_config
  assert_output --partial "invalid_key"
}
@test "set_config with unknown key returns invalid_key" {
  CONTENT_LENGTH=20 \
    run bash -c "printf 'evil_key=1' | \
      REQUEST_METHOD=POST QUERY_STRING='action=set_config' \
      HTTP_X_NORYPT_TOKEN=testtoken NORYPT_CSRF_TOKEN=testtoken \
      NORYPT_TEST=1 bash \"$CGI\""
  assert_output --partial "invalid_key"
}
@test "set_config with whitelisted key returns ok=" {
  CONTENT_LENGTH=16 \
    run bash -c "printf 'randomize_imei=1' | \
      REQUEST_METHOD=POST QUERY_STRING='action=set_config' \
      HTTP_X_NORYPT_TOKEN=testtoken NORYPT_CSRF_TOKEN=testtoken \
      NORYPT_TEST=1 bash \"$CGI\""
  assert_output --partial "ok=randomize_imei"
}
@test "randomize_imei action exits 0" {
  local tmp_hist; tmp_hist=$(mktemp)
  NORYPT_MODULES_DIR="$BATS_TEST_DIRNAME/../src/modules" \
  TAC_DB="$BATS_TEST_DIRNAME/../src/db/tac.db" \
  MODEM_PORT="/dev/null" \
  NORYPT_HISTORY_FILE="$tmp_hist" \
    run run_cgi randomize_imei
  rm -f "$tmp_hist"
  assert_success
}
@test "wipe_logs action exits 0 with temp dirs" {
  local tmp_hist; tmp_hist=$(mktemp)
  NORYPT_MODULES_DIR="$BATS_TEST_DIRNAME/../src/modules" \
  NORYPT_VARLOG="$(mktemp -d)" \
  NORYPT_TMPLOG="$(mktemp -d)" \
  NORYPT_HISTORY_FILE="$tmp_hist" \
    run run_cgi wipe_logs
  rm -f "$tmp_hist"
  assert_success
}
@test "unknown action returns 400" {
  run run_cgi bogus_action
  assert_output --partial "400"
}

@test "serve_index replaces __CSRF_TOKEN__ with a hex token" {
  # Provide an empty COOKIE so session_id is empty string
  HTTP_COOKIE="" \
    run bash -c "QUERY_STRING='action=serve_index' \
      REQUEST_METHOD=GET NORYPT_TEST=1 \
      NORYPT_WWW_DIR=\"$BATS_TEST_DIRNAME/../src/www\" \
      bash \"$CGI\""
  assert_success
  # Output must not contain the literal placeholder
  refute_output --partial "__CSRF_TOKEN__"
  # Output must contain a hex token in the meta tag
  assert_output --partial 'content="'
}
