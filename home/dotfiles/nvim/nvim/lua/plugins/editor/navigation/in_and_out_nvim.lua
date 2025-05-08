-- quickly navigate in and out of surrounding character
return {
  {
    "ysmb-wtsg/in-and-out.nvim",
    lazy = true,
    event = "InsertEnter",
    init = function()
      -- keymaps
      -- in and out of surrounding character
      vim.keymap.set(
        "i",
        "<C-l>",
        function()
          require("in-and-out").in_and_out()
        end,
        { desc = "in and out", silent = true }
      )
    end,
  },
}
