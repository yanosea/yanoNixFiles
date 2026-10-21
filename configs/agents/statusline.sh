#!/usr/bin/env bash
# statusline.sh - powerline-style status line for grok and antigravity, in the
# everforest palette.

set -uo pipefail

input=$(cat)
SEP=$'\xee\x82\xb0' # U+E0B0, as bytes so it needs no UTF-8 locale

j() { echo "$input" | jq -r "$1 // empty" 2>/dev/null; }

hex() {
  local h=${1#\#}
  [[ $h =~ ^[[:xdigit:]]{6}$ ]] || {
    printf '0;0;0'
    return
  }
  printf '%d;%d;%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

# "bg fg bold" of a segment key
colour() {
  case "$1" in
  directory) echo '#a7c080 #2d353b true' ;;
  git) echo '#3d484d #d3c6aa false' ;;
  session) echo '#7fbbb3 #2d353b true' ;;
  context) echo '#3d484d #7fbbb3 false' ;;
  contextWarning) echo '#e69875 #2d353b false' ;;
  contextCritical) echo '#e67e80 #2d353b false' ;;
  weekly) echo '#475258 #d3c6aa false' ;;
  model) echo '#83c092 #2d353b true' ;;
  thinking) echo '#3d484d #d699b6 false' ;;
  version) echo '#2d353b #859289 false' ;;
  *) echo '#3b4252 #d8dee9 false' ;;
  esac
}

# render one line from "key<TAB>text" entries on stdin
render() {
  local out="" prev="" key text bg fg bold
  while IFS=$'\t' read -r key text; do
    [ -z "$text" ] && continue
    read -r bg fg bold <<<"$(colour "$key")"
    [ -n "$prev" ] && out+="\e[38;2;$(hex "$prev")m\e[48;2;$(hex "$bg")m${SEP}"
    out+="\e[48;2;$(hex "$bg")m\e[38;2;$(hex "$fg")m"
    [ "$bold" = true ] && out+="\e[1m"
    out+=" ${text} \e[22m"
    prev=$bg
  done
  [ -z "$prev" ] && return 0
  printf '%b\n' "${out}\e[0m\e[38;2;$(hex "$prev")m${SEP}\e[0m"
}

# ██████░░░░ 60%
bar() {
  local pct=$1 filled i out=""
  filled=$(((pct + 5) / 10))
  [ "$filled" -gt 10 ] && filled=10
  for ((i = 0; i < 10; i++)); do
    if [ "$i" -lt "$filled" ]; then out+="█"; else out+="░"; fi
  done
  printf '%s %d%%' "$out" "$pct"
}

level() {
  if [ "$1" -ge 80 ]; then
    echo contextCritical
  elif [ "$1" -ge "$2" ]; then
    echo contextWarning
  else
    echo "$3"
  fi
}

cwd=$(j '.workspace.current_dir // .cwd')
[ -z "$cwd" ] && cwd=$PWD

# line 1: directory, git
git_text=""
if branch=$(git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$cwd" rev-parse --short HEAD 2>/dev/null); then
  git_text="⎇ $branch"
  read -r behind ahead < <(git -C "$cwd" rev-list --left-right --count '@{upstream}...HEAD' 2>/dev/null || echo "0 0")
  [ "${ahead:-0}" -gt 0 ] && git_text+=" ↑$ahead"
  [ "${behind:-0}" -gt 0 ] && git_text+=" ↓$behind"
  status=$(git -C "$cwd" status --porcelain 2>/dev/null)
  staged=$(echo "$status" | grep -c '^[MADRC]')
  unstaged=$(echo "$status" | grep -c '^.[MD]')
  untracked=$(echo "$status" | grep -c '^??')
  tree=()
  [ "$staged" -gt 0 ] && tree+=("+$staged")
  [ "$unstaged" -gt 0 ] && tree+=("~$unstaged")
  [ "$untracked" -gt 0 ] && tree+=("?$untracked")
  [ ${#tree[@]} -gt 0 ] && git_text+=" (${tree[*]})"
  if [ -n "$status" ]; then git_text+=" ●"; else git_text+=" ✓"; fi
fi
printf 'directory\t%s\ngit\t%s\n' "${cwd/#$HOME/\~}" "$git_text" | render

# line 2: session cost, context
cost=$(j '.cost.total_cost_usd // (.cost | numbers)')
ctx=$(j '.context_window.used_percentage')
{
  [ -n "$cost" ] && printf 'session\t§ $%.2f\n' "$cost"
  if [ -n "$ctx" ]; then
    ctx=${ctx%.*}
    printf '%s\t%s\n' "$(level "$ctx" 60 context)" "$(bar "$ctx")"
  fi
} | render

# line 3: usage limits (antigravity reports weekly quotas)
echo "$input" | jq -r '.quota // {} | to_entries[]
  | "\(.key | sub("-weekly$"; ""))\t\(((1 - .value.remaining_fraction) * 100) | round)\t\((.value.reset_in_seconds // 0) / 86400 | floor)"' 2>/dev/null |
  while IFS=$'\t' read -r name used days; do
    printf '%s\t◑ %s %s (%sd)\n' "$(level "$used" 50 weekly)" "$name" "$(bar "$used")" "$days"
  done | render

# line 4: model, effort, version
{
  model=$(j '.model.display_name // .model.id')
  effort=$(j '.effort.level // .model.effort')
  version=$(j '.version')
  [ -n "$model" ] && printf 'model\t✱ %s\n' "$model"
  [ -n "$effort" ] && printf 'thinking\t✦ %s\n' "$effort"
  if [ -n "$version" ]; then printf 'version\t◈ v%s\n' "$version"; fi
} | render
