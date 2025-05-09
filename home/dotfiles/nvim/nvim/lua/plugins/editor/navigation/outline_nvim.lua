-- a sidebar with a tree-like outline of symbols from the code, powered by LSP
-- keymaps are set in lua/pulugins/tools/internal/which_key_nvim.lua
return {
  {
    "hedyhli/outline.nvim",
    lazy = true,
    cmd = { "Outline" },
    keys = { { "<LEADER>lo", "<CMD>Outline<CR>", desc = "outline", silent = true } },
  },
}
