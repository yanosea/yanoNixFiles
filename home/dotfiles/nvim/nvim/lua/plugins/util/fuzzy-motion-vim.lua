return {
  {
    -- https://github.com/yuki-yano/fuzzy-motion.vim
    "yuki-yano/fuzzy-motion.vim",
    lazy = false,
    dependencies = {
      -- https://github.com/vim-denops/denops.vim
      "vim-denops/denops.vim",
      -- https://github.com/lambdalisue/kensaku.vim
      "lambdalisue/kensaku.vim",
    },
    init = function()
      vim.keymap.set("n", "<LEADER><SPACE>", "<CMD>FuzzyMotion<CR>", { silent = true })
      vim.g.fuzzy_motion_matchers = { "fzf", "kensaku" }
    end,
  },
}
