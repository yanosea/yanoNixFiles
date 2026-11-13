#!/usr/bin/env bash

FloatingVim=$(hyprctl clients -j | jq -c '.[] | select(.class=="FloatingVim")')

if [ -z "$FloatingVim" ]; then
  IS_FLOATING_VIM=1 wezterm --config-file ~/.config/wezterm/wezterm.lua --config initial_rows=10 --config initial_cols=70 --config enable_tab_bar=false --config window_background_opacity=0.4 --config text_background_opacity=0.4 start --class FloatingVim nvim
else
  if [ "$(echo "$FloatingVim" | jq .focusHistoryID)" = '0' ]; then
    hyprctl dispatch "hl.dsp.window.close({ window = \"address:$(echo "$FloatingVim" | jq -r .address)\" })"
  else
    hyprctl dispatch "hl.dsp.focus({ window = \"address:$(echo "$FloatingVim" | jq -r .address)\" })"
  fi
fi
