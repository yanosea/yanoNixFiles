-- a sidebar with a tree-like outline of symbols from the code, powered by LSP
return {
  {
    "hedyhli/outline.nvim",
    lazy = true,
    cmd = { "Outline" },
    keys = { { "<LEADER>lo", "<CMD>Outline<CR>", desc = "outline", silent = true } },
  },
}
