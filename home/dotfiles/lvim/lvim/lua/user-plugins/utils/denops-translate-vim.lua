-- translate text
table.insert(lvim.plugins, {
  "skanehira/denops-translate.vim",
  dependencies = { "vim-denops/denops.vim" },
  event = { "BufRead", "BufEnter" },
  init = function()
    vim.keymap.set("v", "T", "<CMD>'<,'>Translate<CR>", { noremap = true, silent = true, desc = "Translate" })
  end,
})
