-- chatgpt for neovim
table.insert(lvim.plugins, {
  "robitx/gp.nvim",
  cmd = { "GpChatNew", "GpChatPaste", "GpChatToggle" },
  config = function()
    require("gp").setup({
      agents = {
        {
          name = "ChatGPT4",
          chat = true,
          command = false,
          model = { model = "gpt-4o", temperature = 1.1, top_p = 1 },
          system_prompt = require("plugins.user.tools.external.ai.system_prompt").SystemPrompt,
        },
        {
          name = "ChatGPT3-5",
          disable = true,
        },
      },
      state_dir = os.getenv("XDG_STATE_HOME") .. "/gp-nvim/persisted",
      chat_dir = os.getenv("GOOGLE_DRIVE") .. "/gp-nvim/chats",
    })
    vim.api.nvim_set_hl(0, "GpHandlerStandout", { link = "Normal" })
    vim.api.nvim_set_hl(0, "GpExplorerSearch", { link = "Normal" })

    vim.keymap.set("n", "<LEADER>AT", "<CMD>GpChatNew tabnew<CR>", { silent = true, desc = "GpChatNew tabnew" })
    vim.keymap.set("n", "<LEADER>AS", "<CMD>GpChatNew split<CR>", { silent = true, desc = "GpChatNew split" })
    vim.keymap.set("n", "<LEADER>AV", "<CMD>GpChatNew vsplit<CR>", { silent = true, desc = "GpChatNew vsplit" })
    vim.keymap.set("n", "<LEADER>AP", "<CMD>GpChatNew popup<CR>", { silent = true, desc = "GpChatNew popup" })
    vim.keymap.set("n", "<LEADER>AE", "<CMD>GpChatFinder<CR>", { silent = true, desc = "GpChat finder" })
    vim.keymap.set("n", "<LEADER>AA", "<CMD>GpChatRespond<CR>", { silent = true, desc = "GpChat respond" })
    vim.keymap.set("n", "<LEADER>AD", "<CMD>GpChatDelete<CR>", { silent = true, desc = "GpChat delete" })
    vim.keymap.set("n", "<LEADER>AC", "<CMD>GpChatStop<CR>", { silent = true, desc = "GpChat stop" })
  end,
})
