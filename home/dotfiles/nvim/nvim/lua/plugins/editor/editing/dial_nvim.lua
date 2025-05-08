-- extend increment and decrement
return {
  {
    "monaqa/dial.nvim",
    lazy = true,
    keys = { "<C-a>", "<C-x>" },
    init = function()
      -- keymaps
      -- increment
      vim.keymap.set(
        "n",
        "<C-a>",
        function()
          require("dial.map").inc_normal()
        end,
        { desc = "dial increment", silent = true }
      )
      -- decrement
      vim.keymap.set(
        "n",
        "<C-x>",
        function()
          require("dial.map").dec_normal()
        end,
        { desc = "dial decrement", silent = true }
      )
    end,
    config = function()
      require("dial.config").augends:register_group({
        default = {
          require("dial.augend").integer.alias.decimal,
          require("dial.augend").integer.alias.hex,
          require("dial.augend").constant.alias.bool,
          require("dial.augend").semver.alias.semver,
          require("dial.augend").date.alias["%Y/%m/%d"],
          require("dial.augend").date.alias["%Y-%m-%d"],
          require("dial.augend").date.alias["%Y年%m月%d日"],
          require("dial.augend").date.alias["%m月%d日"],
        },
      })
    end,
  },
}
