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
    keys = { "<LEADER>Ct" },
    cmd = { "CopilotChatToggle" },
    opts = {
      debug = true,
    },

    init = function()
      vim.keymap.set("n", "<LEADER>Ct", "<CMD>CopilotChatToggle<CR>")
      vim.keymap.set("n", "<LEADER>Cc", "<CMD>CopilotChatStop<CR>")
    end,
  },
}
