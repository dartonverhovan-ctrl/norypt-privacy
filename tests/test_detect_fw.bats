#!/usr/bin/env bats
load 'test_helper'

DETECT="$BATS_TEST_DIRNAME/../src/modules/detect_fw.sh"

@test "FW_VERSION=v4.5+ when GL version is 4.6.0" {
  result=$(MOCK_GLVERSION="4.6.0" bash -c "source '$DETECT' && echo \$FW_VERSION")
  assert_equal "$result" "v4.5+"
}
@test "FW_VERSION=v4 when GL version is 4.4.0" {
  result=$(MOCK_GLVERSION="4.4.0" bash -c "source '$DETECT' && echo \$FW_VERSION")
  assert_equal "$result" "v4"
}
@test "FW_VERSION=vanilla when no GL version present" {
  result=$(MOCK_GLVERSION="" bash -c "source '$DETECT' && echo \$FW_VERSION")
  assert_equal "$result" "vanilla"
}
@test "IF_WAN defaults to eth0" {
  result=$(MOCK_GLVERSION="4.6.0" bash -c "source '$DETECT' && echo \$IF_WAN")
  assert_equal "$result" "eth0"
}
@test "IF_WAN can be overridden" {
  result=$(MOCK_GLVERSION="4.6.0" IF_WAN_OVERRIDE=eth1 \
           bash -c "source '$DETECT' && echo \$IF_WAN")
  assert_equal "$result" "eth1"
}
@test "MODEM_PORT_OVERRIDE is exported as MODEM_PORT" {
  result=$(MOCK_GLVERSION="4.6.0" \
           MODEM_PORT_OVERRIDE=/dev/ttyUSB2 \
           bash -c "source '$DETECT' && echo \$MODEM_PORT")
  assert_equal "$result" "/dev/ttyUSB2"
}
