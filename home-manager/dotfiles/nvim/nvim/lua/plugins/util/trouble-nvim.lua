return {
  {
    -- https://github.com/folke/trouble.nvim
    "folke/trouble.nvim",
    lazy = true,
    keys = { "<LEADER>T" },
    cmd = { "TroubleToggle" },
    opts = { use_diagnostic_signs = true },
    config = function()
      require("trouble").setup({})
      vim.keymap.set("n", "<LEADER>T", "<CMD>TroubleToggle<CR>")
    end,
  },
}
