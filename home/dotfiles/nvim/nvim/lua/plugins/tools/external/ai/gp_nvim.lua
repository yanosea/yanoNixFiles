-- chatgpt for neovim
return {
  {
    "robitx/gp.nvim",
    lazy = true,
    cmd = { "GpChatNew", "GpChatPaste", "GpChatToggle" },
    init = function()
      for _, mode in ipairs({ "n", "x" }) do
        -- keymaps
        vim.keymap.set(mode, "<LEADER>AT", "<CMD>GpChatNew tabnew<CR>", { desc = "gpchatnew tabnew", silent = true })
        vim.keymap.set(mode, "<LEADER>AS", "<CMD>GpChatNew split<CR>", { desc = "gpchatnew split", silent = true })
        vim.keymap.set(mode, "<LEADER>AV", "<CMD>GpChatNew vsplit<CR>", { desc = "gpchatnew vsplit", silent = true })
        vim.keymap.set(mode, "<LEADER>AP", "<CMD>GpChatNew popup<CR>", { desc = "gpchatnew popup", silent = true })
        vim.keymap.set(mode, "<LEADER>AE", "<CMD>GpChatFinder<CR>", { desc = "gpchat finder", silent = true })
        vim.keymap.set(mode, "<LEADER>AA", "<CMD>GpChatRespond<CR>", { desc = "gpchat respond", silent = true })
        vim.keymap.set(mode, "<LEADER>AD", "<CMD>GpChatDelete<CR>", { desc = "gpchat delete", silent = true })
        vim.keymap.set(mode, "<LEADER>AC", "<CMD>GpChatStop<CR>", { desc = "gpchat stop", silent = true })
      end
    end,
    config = function()
      vim.api.nvim_set_hl(0, "GpHandlerStandout", { link = "Normal" })
      vim.api.nvim_set_hl(0, "GpExplorerSearch", { link = "Normal" })
      -- gp.nvim config
      require("gp").setup({
        agents = {
          {
            name = "ChatGPT4",
            chat = true,
            command = false,
            model = { model = "gpt-4o", temperature = 1.1, top_p = 1 },
            system_prompt = require("plugins.tools.external.ai.prompts.system_prompt").prompt,
          },
          {
            name = "ChatGPT3-5",
            disable = true,
          },
        },
        state_dir = os.getenv("XDG_STATE_HOME") .. "/gp-nvim/persisted",
        chat_dir = os.getenv("GOOGLE_DRIVE") .. "/gp-nvim/chats",
      })
    end,
  },
}
