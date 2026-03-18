#!/usr/bin/env bash
# Prepend mocks dir so tests intercept system commands
export PATH="$BATS_TEST_DIRNAME/mocks:$PATH"
export NORYPT_TEST=1

load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
