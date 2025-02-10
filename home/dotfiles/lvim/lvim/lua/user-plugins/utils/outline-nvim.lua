-- a sidebar with a tree-like outline of symbols from the code, powered by LSP
table.insert(lvim.plugins, {
  "hedyhli/outline.nvim",
  cmd = { "Outline" },
  init = function()
    require("outline").setup({})
    vim.keymap.set("n", "<LEADER>lo", "<CMD>Outline<CR>", { silent = true, desc = "Outline" })
  end,
})
