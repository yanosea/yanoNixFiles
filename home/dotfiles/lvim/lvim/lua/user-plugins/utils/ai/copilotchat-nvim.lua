-- github copilot chat for neovim
table.insert(lvim.plugins, {
  "CopilotC-Nvim/CopilotChat.nvim",
  dependencies = {
    "github/copilot.vim",
    "nvim-lua/plenary.nvim",
  },
  cmd = { "CopilotChat", "CopilotChatBuffer" },
  opts = {
    debug = true,
  },
  init = function()
    vim.keymap.set("n", "<LEADER>Ct", "<CMD>CopilotChat<CR>", { silent = true, desc = "CopilotChat chat" })
    vim.keymap.set("n", "<LEADER>Cc", "<CMD>CopilotChatStop<CR>", { silent = true, desc = "CopilotChat stop" })
    vim.keymap.set("n", "<LEADER>Cs", "<CMD>CopilotChatSave<CR>", { silent = true, desc = "CopilotChat save" })
    vim.keymap.set("n", "<LEADER>Cl", "<CMD>CopilotChatLoad<CR>", { silent = true, desc = "CopilotChat load" })
    vim.api.nvim_set_keymap(
      "n",
      "<LEADER>Cq",
      "<CMD>lua CopilotChatBuffer()<CR>",
      { noremap = true, silent = true, desc = "CopilotChat quick chat" }
    )
  end,
})

function CopilotChatBuffer()
  local input = vim.fn.input("Quick Chat: ")
  if input ~= "" then
    require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
  end
end
