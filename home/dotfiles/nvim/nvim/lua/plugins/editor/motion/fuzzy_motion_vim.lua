-- jump to fuzzy match word
return {
  {
    "yuki-yano/fuzzy-motion.vim",
    dependencies = {
      "vim-denops/denops.vim",
      "lambdalisue/kensaku.vim",
    },
    lazy = true,
    event = "VeryLazy",
    init = function()
      -- keymaps
      -- fuzzy motion
      vim.keymap.set("n", "<LEADER><SPACE>", "<CMD>FuzzyMotion<CR>", { desc = "fuzzy motion", silent = true })
    end,
    config = function()
      vim.g.fuzzy_motion_matchers = { "fzf", "kensaku" }
    end,
  },
}
