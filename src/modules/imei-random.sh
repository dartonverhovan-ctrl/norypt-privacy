#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/luhn.sh"

TAC_DB="${TAC_DB:-${SCRIPT_DIR}/../db/tac.db}"
MODEM_PORT="${MODEM_PORT:-}"
AT_RETRIES=3
MODEM_WAIT=15

_log() { logger -t norypt "imei: $*" 2>/dev/null || echo "norypt imei: $*" >&2; }

_wait_for_modem() {
  [[ -n "${NORYPT_TEST:-}" ]] && return 0
  for _ in $(seq 1 "${MODEM_WAIT}"); do
    [[ -e "${MODEM_PORT}" ]] && return 0
    sleep 1
  done
  _log "modem port ${MODEM_PORT} not found after ${MODEM_WAIT}s — skipping IMEI"
  return 1
}

_at() {
  local cmd="$1"
  # send_at handles the serial I/O when on PATH (mocks in test, real binary in prod)
  if command -v send_at >/dev/null 2>&1; then
    send_at "${MODEM_PORT}" "${cmd}"
  else
    # Fallback: Use stty + single fd for reliable serial AT I/O on the RM520N-GL
    # Baud rate 115200, raw mode, no echo
    stty -F "${MODEM_PORT}" 115200 raw -echo 2>/dev/null || true
    local response
    # Open port once for both write and read using a file descriptor
    exec 3<>"${MODEM_PORT}"
    printf 'AT%s\r' "${cmd}" >&3
    sleep 0.3
    response=$(head -c 256 <&3)
    exec 3>&-
    echo "${response}"
  fi
}

_generate_imei() {
  # shuf provides unbiased urandom-seeded line selection (coreutils-shuf dep)
  local tac
  tac=$(shuf -n1 "${TAC_DB}")
  local serial
  serial=$(od -An -N3 -tu1 /dev/urandom | \
           awk '{printf "%06d", ($1*65536+$2*256+$3) % 1000000}')
  local prefix="${tac}${serial}"
  local check
  check=$(luhn_digit "${prefix}")
  echo "${prefix}${check}"
}

main() {
  local new_imei
  new_imei=$(_generate_imei)

  if [[ -n "${NORYPT_TEST:-}" ]]; then
    echo "${new_imei}"
    return 0
  fi

  _wait_for_modem
  local modem_ok=$?
  if [[ "${modem_ok}" -ne 0 ]]; then return 1; fi

  _at '+QCFG="IMEI/LOCK",0' >/dev/null

  local attempt=0
  while [[ "${attempt}" -lt "${AT_RETRIES}" ]]; do
    _at "+EGMR=1,7,\"${new_imei}\"" >/dev/null
    local verified
    verified=$(_at "+CGSN" | grep -oE '[0-9]{15}' | head -1)
    if [[ "${verified}" = "${new_imei}" ]]; then
      _log "IMEI set to ${new_imei}"
      echo "${new_imei}"
      return 0
    fi
    attempt=$(( attempt + 1 ))
    sleep 1
  done

  _log "IMEI verification failed after ${AT_RETRIES} attempts"
  return 1
}

main "$@"
