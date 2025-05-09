-- notification
return {
  {
    "rcarriga/nvim-notify",
    lazy = true,
    event = "UIEnter",
    config = function()
      vim.notify = require("notify")
      require("notify").setup({
        fps = 60,
        colors = {
          error = "#e67e80", -- everforest red
          warn = "#dbbc7f", -- everforest yellow
          info = "#83c092", -- everforest sage green
          debug = "#7fbbb3", -- everforest blue
          trace = "#d3c6aa", -- everforest foreground
        },
        render = "compact",
        timeout = 500,
        top_down = false,
      })
    end,
  },
}
