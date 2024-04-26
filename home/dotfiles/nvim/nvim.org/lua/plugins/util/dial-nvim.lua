return {
  {
    -- https://github.com/monaqa/dial.nvim
    "monaqa/dial.nvim",
    lazy = true,
    keys = { "<C-a>", "<C-x>" },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.constant.alias.bool,
          augend.semver.alias.semver,
          augend.date.alias["%Y/%m/%d"],
          augend.date.alias["%Y-%m-%d"],
          augend.date.alias["%Y年%m月%d日"],
          augend.date.alias["%m月%d日"],
        },
      })
      vim.keymap.set("n", "<C-a>", require("dial.map").inc_normal(), { noremap = true })
      vim.keymap.set("n", "<C-x>", require("dial.map").dec_normal(), { noremap = true })
    end,
  },
}
