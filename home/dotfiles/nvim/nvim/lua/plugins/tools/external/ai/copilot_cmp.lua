-- github copilot completion plugin for cmp
return {
  {
    "zbirenbaum/copilot-cmp",
    dependencies = { "zbirenbaum/copilot.lua" },
    lazy = true,
    event = "InsertEnter",
    config = function()
      vim.defer_fn(function()
        require("copilot").setup()
        require("copilot_cmp").setup()
      end, 100)
    end,
  },
}
