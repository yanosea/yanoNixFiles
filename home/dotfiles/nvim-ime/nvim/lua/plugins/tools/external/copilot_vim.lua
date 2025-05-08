-- github copilot for vim
return {
  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      vim.g.copilot_no_tab_map = true

      vim.api.nvim_set_keymap(
        "i",
        "<C-a><C-a>",
        'copilot#Accept("<CR>") . "\\<Esc>"',
        { silent = true, desc = "Copilot accept", expr = true }
      )
      vim.keymap.set("i", "<C-a>n", "<Plug>(copilot-next)", { silent = true, desc = "Copilot next" })
      vim.keymap.set("i", "<C-a>b", "<Plug>(copilot-previous)", { silent = true, desc = "Copilot previous" })
      vim.keymap.set("i", "<C-a>d", "<Plug>(copilot-dismiss)", { silent = true, desc = "Copilot dismiss" })
      vim.keymap.set("i", "<C-a><Space>", "<Plug>(copilot-suggest)", { silent = true, desc = "Copilot suggest" })
    end,
  },
}
