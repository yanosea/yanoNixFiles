#!/usr/bin/env bash

MONITOR=$1

if pgrep -f "wf-recorder.*-o $MONITOR" >/dev/null 2>&1; then
  echo ""
fi
