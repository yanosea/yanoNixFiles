-- markdown preview
return {
  {
    "toppair/peek.nvim",
    lazy = true,
    ft = { "markdown" },
    build = "deno task --quiet build:fast",
    config = function()
      vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
      vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
      -- peek.nvim config
      require("peek").setup({
        auto_load = true,
        close_on_bdelete = true,
        syntax = true,
        theme = "dark",
        update_on_change = true,
        app = "browser",
        filetype = { "markdown" },
        throttle_at = 200000,
        throttle_time = "auto",
      })
    end,
  },
}
