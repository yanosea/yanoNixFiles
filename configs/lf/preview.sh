#!/usr/bin/env bash
# lf preview script with chafa for cross-platform image preview

file="$1"
width="$2"
height="$3"
x="$4"
y="$5"

# Get MIME type
mime_type=$(file --mime-type -Lb "$file")

case "$mime_type" in
image/*)
  # Use chafa for image preview with appropriate size
  # chafa supports multiple terminal protocols including sixel, kitty, and iterm2
  chafa -f symbols -s "${width}x${height}" "$file"
  ;;
text/*)
  # Use bat for syntax highlighting if available, otherwise cat
  if command -v bat >/dev/null 2>&1; then
    bat --color=always --style=plain --pager=never "$file"
  else
    cat "$file"
  fi
  ;;
*)
  # For other file types, show file information
  file -b "$file"
  ;;
esac
