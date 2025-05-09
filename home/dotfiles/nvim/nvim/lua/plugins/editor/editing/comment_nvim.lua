-- comment utilizes the same keybinding as the default comment plugin
-- keymaps are set in lua/pulugins/tools/internal/which_key_nvim.lua
return {
 {
    "numToStr/Comment.nvim",
    lazy = true,
    event = "BufReadPost",
    keys = { { "gc", mode = { "n", "v" } }, { "gb", mode = { "n", "v" } } },
  },
}
