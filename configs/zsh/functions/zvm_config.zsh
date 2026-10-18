function zvm_config() {
  ZVM_NORMAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
  ZVM_INSERT_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
  ZVM_VISUAL_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
  ZVM_VISUAL_LINE_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
  ZVM_OPPEND_MODE_CURSOR=$ZVM_CURSOR_BLINKING_BLOCK
}

function zvm_after_init() {
  source <(fzf --zsh)
  # replace the ctrl-r widget that fzf --zsh just bound
  bindkey -M emacs '^R' _fzf_history_with_delete
  bindkey -M viins '^R' _fzf_history_with_delete
  bindkey -M vicmd '^R' _fzf_history_with_delete
}
