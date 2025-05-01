-- notification
table.insert(lvim.plugins, {
  "rcarriga/nvim-notify",
  event = "UIEnter",
  config = function()
    vim.notify = require("notify")
    require("notify").setup({
      fps = 60,
      colors = {
        error = "#e67e80", -- Everforest red
        warn = "#dbbc7f", -- Everforest yellow
        info = "#83c092", -- Everforest sage green
        debug = "#7fbbb3", -- Everforest blue
        trace = "#d3c6aa", -- Everforest foreground
      },
      render = "compact",
      timeout = 500,
      top_down = false,
    })
  end,
})
