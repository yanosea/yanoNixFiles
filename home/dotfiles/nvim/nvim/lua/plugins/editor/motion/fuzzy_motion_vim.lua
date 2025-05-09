-- jump to fuzzy match word
-- keymaps are set in lua/pulugins/tools/internal/which_key_nvim.lua
return {
  {
    "yuki-yano/fuzzy-motion.vim",
    dependencies = {
      "vim-denops/denops.vim",
      "lambdalisue/kensaku.vim",
    },
    lazy = true,
    event = "VeryLazy",
    config = function()
      vim.g.fuzzy_motion_matchers = { "fzf", "kensaku" }
    end,
  },
}
