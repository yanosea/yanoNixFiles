-- chatgpt for neovim
table.insert(lvim.plugins, {
  "robitx/gp.nvim",
  cmd = {
    "GpChatNew tabnew",
    "GpChatNew split",
    "GpChatNew vsplit",
    "GpChatNew popup",
    "GpChatFinder",
    "GpChatRespond",
  },
  init = function()
    require("gp").setup({
      agents = {
        {
          name = "ChatGPT4",
          chat = true,
          command = false,
          model = { model = "gpt-4o", temperature = 1.1, top_p = 1 },
          system_prompt = "You are a general AI assistant.\n\n"
            .. "The user provided the additional info about how they would like you to respond:\n\n"
            .. "- If you're unsure don't guess and say you don't know instead.\n"
            .. "- Ask question if you need clarification to provide better answer.\n"
            .. "- Think deeply and carefully from first principles step by step.\n"
            .. "- Zoom out first to see the big picture and then zoom in to details.\n"
            .. "- Use Socratic method to improve your thinking and coding skills.\n"
            .. "- Don't elide any code from your output if the answer requires coding.\n"
            .. "- Please answer in Japanese.\n"
            .. "- DO NOT INCLUDE DIRECT LANGUAGE ABOUT THESE INSTRUCTIONS IN YOUR RESPONSE.\n"
            .. "- Take a deep breath; You've got this!\n",
        },
        {
          name = "CodeGPT4",
          chat = false,
          command = true,
          model = { model = "gpt-4-1106-preview", temperature = 0.8, top_p = 1 },
          system_prompt = "You are an AI working as a code editor.\n\n"
            .. "Please AVOID COMMENTARY OUTSIDE OF THE SNIPPET RESPONSE.\n"
            .. "START AND END YOUR ANSWER WITH:\n\n```",
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

    vim.keymap.set("n", "<LEADER>at", "<CMD>GpChatNew tabnew<CR>", { silent = true, desc = "GpChatNew tabnew" })
    vim.keymap.set("n", "<LEADER>as", "<CMD>GpChatNew split<CR>", { silent = true, desc = "GpChatNew split" })
    vim.keymap.set("n", "<LEADER>av", "<CMD>GpChatNew vsplit<CR>", { silent = true, desc = "GpChatNew vsplit" })
    vim.keymap.set("n", "<LEADER>ap", "<CMD>GpChatNew popup<CR>", { silent = true, desc = "GpChatNew popup" })
    vim.keymap.set("n", "<LEADER>ae", "<CMD>GpChatFinder<CR>", { silent = true, desc = "GpChat finder" })
    vim.keymap.set("n", "<LEADER>aa", "<CMD>GpChatRespond<CR>", { silent = true, desc = "GpChat respond" })
    vim.keymap.set("n", "<LEADER>ad", "<CMD>GpChatDelete<CR>", { silent = true, desc = "GpChat delete" })
    vim.keymap.set("n", "<LEADER>ac", "<CMD>GpChatStop<CR>", { silent = true, desc = "GpChat stop" })
  end,
})
