#!/usr/bin/env bats
load 'test_helper'

setup() {
  export NORYPT_TEST=1
  FAKE_VARLOG=$(mktemp -d)
  FAKE_TMPLOG=$(mktemp -d)
  touch "$FAKE_VARLOG/messages" "$FAKE_VARLOG/syslog"
  touch "$FAKE_TMPLOG/runtime.log"
  export NORYPT_VARLOG="$FAKE_VARLOG" NORYPT_TMPLOG="$FAKE_TMPLOG"
}
teardown() { rm -rf "$FAKE_VARLOG" "$FAKE_TMPLOG"; }

@test "log-wipe.sh exits 0" {
  run bash "$BATS_TEST_DIRNAME/../src/modules/log-wipe.sh"
  assert_success
}
@test "files in VARLOG are removed" {
  bash "$BATS_TEST_DIRNAME/../src/modules/log-wipe.sh"
  [ -z "$(ls -A "$FAKE_VARLOG")" ]
}
@test "files in TMPLOG are removed" {
  bash "$BATS_TEST_DIRNAME/../src/modules/log-wipe.sh"
  [ -z "$(ls -A "$FAKE_TMPLOG")" ]
}

@test "log restart is called in non-test mode" {
  LOG_RESTART_CMD="$BATS_TEST_DIRNAME/mocks/log_restart_mock"
  printf '#!/usr/bin/env bash\necho "restarted" > /tmp/norypt_log_restarted\n' \
    > "$LOG_RESTART_CMD" && chmod +x "$LOG_RESTART_CMD"
  NORYPT_TEST="" NORYPT_LOG_RESTART="$LOG_RESTART_CMD" \
    bash "$BATS_TEST_DIRNAME/../src/modules/log-wipe.sh" >/dev/null 2>&1 || true
  [ -f /tmp/norypt_log_restarted ]
  rm -f /tmp/norypt_log_restarted "$LOG_RESTART_CMD"
}
