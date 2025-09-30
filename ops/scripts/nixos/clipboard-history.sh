#!/usr/bin/env bash

FloatingClipse=$(hyprctl clients -j | jq -c '.[] | select(.class=="FloatingClipse")')

if [ -z "$FloatingClipse" ]; then
  wezterm --config-file ~/.config/wezterm/wezterm.lua --config initial_rows=40 --config initial_cols=110 --config enable_tab_bar=false --config window_background_opacity=0.4 --config text_background_opacity=0.4 start --class FloatingClipse clipse
else
  if [ "$(echo "$FloatingClipse" | jq .focusHistoryID)" = '0' ]; then
    hyprctl dispatch closewindow "address:$(echo "$FloatingClipse" | jq -r .address)"
  else
    hyprctl dispatch focuswindow "address:$(echo "$FloatingClipse" | jq -r .address)"
  fi
fi
