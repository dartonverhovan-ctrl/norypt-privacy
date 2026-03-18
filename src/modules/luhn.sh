#!/usr/bin/env bash
# luhn.sh — Luhn check digit computation
# Source this file to use luhn_digit()
# Usage: check=$(luhn_digit "35394110123456")  -> returns "3"

luhn_digit() {
  local digits="$1"
  local sum=0 len=${#digits} i d
  for (( i=0; i<len; i++ )); do
    d="${digits:${i}:1}"
    if (( (len - i) % 2 == 0 )); then
      d=$(( d * 2 ))
      (( d > 9 )) && d=$(( d - 9 ))
    fi
    sum=$(( sum + d ))
  done
  echo $(( (10 - (sum % 10)) % 10 ))
}
