-- a sidebar with a tree-like outline of symbols from the code, powered by LSP
table.insert(lvim.plugins, {
  "hedyhli/outline.nvim",
  cmd = { "Outline" },
  keys = { { "<LEADER>lo", "<CMD>Outline<CR>", desc = "Outline" } },
  opts = {},
})
