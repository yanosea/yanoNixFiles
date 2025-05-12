-- Copilotプラグイン
return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
  -- Copilot-CMPインテグレーション
  {
    "zbirenbaum/copilot-cmp",
    config = true,
    event = "InsertEnter",
  },
}
