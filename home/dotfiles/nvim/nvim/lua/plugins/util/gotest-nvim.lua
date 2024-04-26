return {
  {
    -- https://github.com/CadeMichael/gotest.nvim
    "CadeMichael/gotest.nvim",
    lazy = true,
    ft = "go",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      vim.g.gotest = {
        test_cmd = "go test -run ",
        preview_cutoff = 0,
        preview_width = 0.67,
      }
      vim.keymap.set("n", "<Space>tf", require("gotest").goFuncTester)
      vim.keymap.set("n", "<Space>tm", require("gotest").goModTester)
    end,
  },
}
