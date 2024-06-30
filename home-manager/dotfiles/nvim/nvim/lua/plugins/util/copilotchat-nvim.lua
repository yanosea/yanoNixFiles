return {
  {
    -- https://github.com/CopilotC-Nvim/CopilotChat.nvim
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      -- https://github.com/github/copilot.vim
      "github/copilot.vim",
      -- https://github.com/nvim-lua/plenary.nvim
      "nvim-lua/plenary.nvim",
    },
    lazy = true,
    keys = { "<LEADER>ct" },
    cmd = { "CopilotChatToggle" },
    opts = {
      debug = true,
    },

    init = function()
      vim.keymap.set("n", "<LEADER>ct", "<CMD>CopilotChatToggle<CR>")
      vim.keymap.set("n", "<LEADER>cc", "<CMD>CopilotChatStop<CR>")
    end,
  },
}
