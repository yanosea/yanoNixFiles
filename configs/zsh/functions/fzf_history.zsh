# fzf history functions
_fzf_history_with_delete() {
  local marked
  marked=$(command mktemp) || return 1
  # ctrl-d marks the entry numbers and hides them; the files are rewritten after fzf exits
  FZF_CTRL_R_OPTS="${FZF_CTRL_R_OPTS-} --bind='ctrl-d:execute-silent(cat {+f1} >> $marked)+exclude-multi'" \
    zle fzf-history-widget
  local ret=$?
  [[ -s $marked ]] && _fzf_history_delete "$marked"
  command rm -f -- "$marked"
  return $ret
}
zle -N _fzf_history_with_delete

_fzf_history_delete() {
  zmodload -F zsh/parameter p:history
  local -a targets files
  local n file
  for n in ${(f)"$(<$1)"}; do
    n=${n%%[^0-9]*}
    [[ -n $n ]] && (( $+history[$n] )) && targets+=("$history[$n]")
  done
  (( $#targets )) || return 0
  files=("$HISTFILE")
  if (( $+functions[_per-directory-history-switch-context] )); then
    if [[ $_per_directory_history_is_global == true ]]; then
      _per-directory-history-file "$PWD"
      files+=("$REPLY")
    else
      files+=("$_per_directory_history_global_history")
    fi
  fi
  for file in "${files[@]}"; do
    [[ -f $file ]] || continue
    (
      setopt no_hist_ignore_all_dups no_hist_ignore_dups no_hist_expire_dups_first
      fc -p "$file" 1000000 1000000
      # keep this subshell from saving the list it read
      HISTFILE=
      SAVEHIST=0
      # event numbers equal record ordinals right after fc -p, so collect ordinals whose text matches
      local -a ordinals
      local i
      for i in {1..$#history}; do
        (( ${targets[(Ie)$history[$i]]} )) && ordinals+=($i)
      done
      (( $#ordinals )) || exit 0
      # a line ending in a backslash continues the record, as zsh reads it
      command perl -i -e '
        my %drop = map { $_ => 1 } split /,/, shift;
        my ($n, $rec) = (0, "");
        while (<>) {
          $rec .= $_;
          next if /\\\n\z/ && !eof;
          print $rec unless !/\\\n\z/ && $drop{++$n};
          $rec = "";
        }
      ' -- "${(j:,:)ordinals}" "$file"
    )
  done
  # reload the shown list so the deleted entries leave memory too
  if (( $+functions[_per-directory-history-switch-context] )); then
    _per-directory-history-switch-context "$HISTFILE"
  else
    local histsize=$HISTSIZE savehist=$SAVEHIST
    fc -AI
    SAVEHIST=0
    fc -p "$HISTFILE" $histsize $savehist
  fi
}
