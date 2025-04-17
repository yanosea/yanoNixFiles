-- markdown preview
table.insert(lvim.plugins, {
  "toppair/peek.nvim",
  ft = { "markdown" },
  build = "deno task --quiet build:fast",
  config = function()
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
    vim.api.nvim_create_user_command("PeekOpen", require("peek").open, {})
    vim.api.nvim_create_user_command("PeekClose", require("peek").close, {})
  end,
})
