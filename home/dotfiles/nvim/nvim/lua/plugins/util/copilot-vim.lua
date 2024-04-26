return {
  {
    -- https://github.com/github/copilot.vim
    "github/copilot.vim",
    lazy = false,
    init = function()
      vim.g.copilot_no_tab_map = true
      vim.api.nvim_set_keymap("i", "<C-a><TAB>", 'copilot#Accept("<CR>")', { silent = true, expr = true })
      vim.keymap.set("i", "<C-a><C-j>", "<Plug>(copilot-next)")
      vim.keymap.set("i", "<C-a><C-k>", "<Plug>(copilot-previous)")
      vim.keymap.set("i", "<C-a><C-d>", "<Plug>(copilot-dismiss)")
      vim.keymap.set("i", "<C-a><C-s>", "<Plug>(copilot-suggest)")
    end,
  },
}
