return {
  {
    -- https://github.com/cshuaimin/ssr.nvim
    "cshuaimin/ssr.nvim",
    lazy = false,
    module = "ssr",
    vim.keymap.set({ "n", "x" }, "<leader>sr", function()
      require("ssr").open()
    end),
    config = function()
      require("ssr").setup({
        border = "rounded",
        min_width = 50,
        min_height = 5,
        max_width = 120,
        max_height = 25,
        keymaps = {
          close = "<ESC>",
          next_match = "n",
          prev_match = "N",
          replace_confirm = "<CR>",
          replace_all = "<LEADER><CR>",
        },
      })
    end,
  },
}
