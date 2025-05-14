-- comment utilizes the same keybinding as the default comment plugin
-- keymaps are set in lua/pulugins/tools/internal/which_key_nvim.lua (<LEADER>/)
return {
  {
    "numToStr/Comment.nvim",
    lazy = true,
    event = { "BufReadPost", "BufNewFile" },
  },
}
