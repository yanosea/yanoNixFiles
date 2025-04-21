-- translate text
table.insert(lvim.plugins, {
  "skanehira/denops-translate.vim",
  event = "VeryLazy",
  dependencies = { "vim-denops/denops.vim" },
  init = function()
    -- visual mode mapping for selection translation
    vim.api.nvim_set_keymap(
      "v",
      "<LEADER>T",
      ":'<,'>Translate<CR>",
      { noremap = true, silent = true, desc = "Translate selection" }
    )
    -- normal mode mapping for line translation
    vim.api.nvim_set_keymap(
      "n",
      "<LEADER>T",
      "<CMD>Translate<CR>",
      { noremap = true, silent = true, desc = "Translate current line" }
    )
  end,
})
