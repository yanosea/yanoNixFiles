return {
  {
    -- https://github.com/brenoprata10/nvim-highlight-colors
    "brenoprata10/nvim-highlight-colors",
    lazy = true,
    event = "BufRead",
    config = function()
      require("nvim-highlight-colors").setup({
        render = "background",
        enable_named_colors = true,
        enable_tailwind = true,
      })
    end,
  },
}
