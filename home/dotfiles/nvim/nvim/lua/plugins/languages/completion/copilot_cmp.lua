-- copilot cmp config
return {
  {
    "zbirenbaum/copilot-cmp",
    dependencies = { "zbirenbaum/copilot.lua" },
    lazy = true,
    event = "InsertEnter",
    init = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
    config = true,
  },
}
