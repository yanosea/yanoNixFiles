-- github copilot completion plugin for cmp
return {
  {
    "zbirenbaum/copilot-cmp",
    dependencies = { "zbirenbaum/copilot.lua" },
    lazy = true,
    event = "InsertEnter",
    config = function()
      require("copilot_cmp").setup({
        suggestion = { enabled = true },
        panel = { enabled = true },
      })
    end,
  },
}
