return {
  {
    -- https://github.com/folke/which-key.nvim
    "folke/which-key.nvim",
    lazy = false,
    cond = not vim.g.started_by_firenvim,
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 500
      require("which-key").setup()
      -- require("which-key").register(
      --   {
      --     ["<C-l>"] = 'whole lines',
      --     ["<C-n>"] = 'keywords in the current file',
      --     ["<C-k>"] = 'keywords in dictionary',
      --     ["<C-t>"] = 'keywords in thesaurus',
      --     ["<C-i>"] = 'keywords in the current and included files',
      --     ["<C-]>"] = 'tags',
      --     ["<C-f>"] = 'file names',
      --     ["<C-d>"] = 'definitions or macros',
      --     ["<C-v>"] = 'vim command-line',
      --     ["<C-u>"] = 'user defined completion',
      --     ["<C-o>"] = 'omni completion',
      --     ["<C-s>"] = 'spelling suggestions',
      --     ["<C-z>"] = 'stop completion',
      --   },
      --   {
      --     mode = "i",
      --     prefix = "<C-x>",
      --   }
      -- )
    end,
  },
}
