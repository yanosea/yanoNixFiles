-- show history of yanks and deletions
table.insert(lvim.plugins, {
  "vim-scripts/YankRing.vim",
  cmd = "YRShow",
  init = function()
    vim.g.yankring_history_dir = os.getenv("XDG_STATE_HOME") .. "/yankring"

    vim.keymap.set("n", "<LEADER>yh", "<CMD>YRShow<CR>", { silent = true, desc = "YankRing Show" })
    vim.g.yankring_replace_n_pkey = "<C-y><C-p>"
    vim.g.yankring_replace_n_nkey = "<C-y><C-n>"
  end,
})
