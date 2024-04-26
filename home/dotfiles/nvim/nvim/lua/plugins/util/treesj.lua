return {
  {
    -- https://github.com/Wansmer/treesj
    "Wansmer/treesj",
    lazy = true,
    cmd = { "TSJToggle" },
    init = function()
      require("treesj").setup({
        use_default_keymaps = false,
        check_syntax_error = true,
        max_join_length = 240,
        cursor_behavior = "hold",
        notify = true,
        dot_repeat = true,
        on_error = nil,
      })
    end,
  },
}
