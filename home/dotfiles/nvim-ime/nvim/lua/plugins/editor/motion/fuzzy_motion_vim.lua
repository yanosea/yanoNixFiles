-- jump to fuzzy match word
return {
  {
    "yuki-yano/fuzzy-motion.vim",
    event = "VeryLazy",
    dependencies = {
      "vim-denops/denops.vim",
      "lambdalisue/kensaku.vim",
    },
    init = function()
      vim.g.fuzzy_motion_matchers = { "fzf", "kensaku" }

      vim.keymap.set("n", "<LEADER><SPACE>", "<CMD>FuzzyMotion<CR>", { silent = true, desc = "FuzzyMotion" })
    end,
  },
}
