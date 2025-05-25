#!/bin/sh

killall dropbear

if [ -f /tmp/dropbear-connected-to-wifi ]; then
  rm -f /tmp/dropbear-connected-to-wifi
  /ebrmain/bin/netagent disconnect
fi
