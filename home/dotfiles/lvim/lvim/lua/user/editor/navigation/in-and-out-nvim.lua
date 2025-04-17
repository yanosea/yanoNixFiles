-- quickly navigate in and out of surrounding character
table.insert(lvim.plugins, {
  "ysmb-wtsg/in-and-out.nvim",
  keys = { "<C-l>" },
  init = function()
    vim.keymap.set("i", "<C-l>", function()
      require("in-and-out").in_and_out()
    end, { desc = "In and Out" })
  end,
})
