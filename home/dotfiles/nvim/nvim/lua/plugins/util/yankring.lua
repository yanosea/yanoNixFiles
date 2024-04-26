return {
  {
    -- https://github.com/vim-scripts/YankRing.vim
    "vim-scripts/YankRing.vim",
    lazy = true,
    keys = { "<C-y><C-h>", "<C-y><C-p>", "<C-y><C-n>" },
    cmd = { "YRShow" },
    init = function()
      vim.g.yankring_history_dir = os.getenv("XDG_STATE_HOME") .. "/yankring"
      vim.keymap.set("n", "<C-y><C-h>", "<CMD>YRShow<CR>")
      vim.g.yankring_replace_n_pkey = "<C-y><C-p>"
      vim.g.yankring_replace_n_nkey = "<C-y><C-n>"
    end,
  },
}
