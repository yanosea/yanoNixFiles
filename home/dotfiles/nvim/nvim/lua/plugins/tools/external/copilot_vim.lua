-- github copilot for vim
return {
  {
    "github/copilot.vim",
    lazy = true,
    event = "InsertEnter",
    init = function()
      -- keymaps
      -- accept suggestion
      vim.api.nvim_set_keymap(
        "i",
        "<C-a><C-a>",
        'copilot#Accept("<CR>") . "\\<Esc>"',
        { desc = "copilot accept", silent = true, expr = true }
      )
      -- next suggestion
      vim.keymap.set("i", "<C-a>n", "<Plug>(copilot-next)", { desc = "copilot next", silent = true })
      -- previous suggestion
      vim.keymap.set("i", "<C-a>b", "<Plug>(copilot-previous)", { desc = "copilot previous", silent = true })
      -- dismiss suggestion
      vim.keymap.set("i", "<C-a>d", "<Plug>(copilot-dismiss)", { desc = "copilot dismiss", silent = true })
      -- show suggestion
      vim.keymap.set("i", "<C-a><Space>", "<Plug>(copilot-suggest)", { desc = "copilot suggest", silent = true })
    end,
    config = function()
      -- disable default keymap
      vim.g.copilot_no_tab_map = true
    end,
  },
}
