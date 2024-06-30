-- extend increment and decrement
table.insert(lvim.plugins, {
  "monaqa/dial.nvim",
  event = { "BufRead", "BufEnter" },
  init = function()
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

    vim.keymap.set(
      "n",
      "<C-a>",
      require("dial.map").inc_normal(),
      { noremap = true, silent = true, desc = "Dial Increment" }
    )
    vim.keymap.set(
      "n",
      "<C-x>",
      require("dial.map").dec_normal(),
      { noremap = true, silent = true, desc = "Dial Decrement" }
    )
  end,
})
