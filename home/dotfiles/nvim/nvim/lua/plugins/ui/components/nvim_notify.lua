-- notification
return {
  {
    "rcarriga/nvim-notify",
    lazy = true,
    event = "UIEnter",
    config = function()
      local colors = require("utils.colors").colors
      vim.notify = require("notify")
      require("notify").setup({
        fps = 60,
        colors = {
          error = colors.Red,
          warn = colors.Yellow,
          info = colors.Green,
          debug = colors.Blue,
          trace = colors.Purple,
        },
        render = "compact",
        timeout = 500,
        top_down = false,
      })
    end,
  },
}
