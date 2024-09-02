-- which-key.nvim
-- chatgpt
lvim.builtin.which_key.mappings["a"] = {
  name = "+Chatgpt",
  -- GpChatNew tabnew
  t = { "<CMD>GpChatNew tabnew<CR>", "GpChatNew tabnew" },
  -- GpChatNew split
  s = { "<CMD>GpChatNew split<<CR>", "GpChatNew split" },
  -- GpChatNew vsplit
  v = { "<CMD>GpChatNew vsplit<CR>", "GpChatNew vsplit" },
  -- GpChatNew popup
  p = { "<CMD>GpChatNew popup<CR>", "GpChatNew popup" },
  -- GpChatFinder
  e = { "<CMD>GpChatFinder<CR>", "GpChatFinder" },
}
-- copilot chat
lvim.builtin.which_key.mappings["C"] = {
  name = "+CopilotChat",
  -- CopilotChat
  t = { "<CMD>CopilotChat<CR>", "CopilotChat chat" },
  -- CopilotChatStop
  c = { "<CMD>CopilotChatStop<CR>", "CopilotChat stop" },
  -- CopilotChatSave
  s = { "<CMD>CopilotChatSave<CR>", "CopilotChat save" },
  -- CopilotChatLoad
  l = { "<CMD>CopilotChatLoad<CR>", "CopilotChat load" },
  -- CopilotChatDocs
  d = { "<CMD>CopilotChatDocs<CR>", "CopilotChat docs" },
  -- CopilotChatFix
  f = { "<CMD>CopilotChatFix<CR>", "CopilotChat fix" },
  -- CopilotChatReview
  r = { "<CMD>CopilotChatReview<CR>", "CopilotChat review" },
  -- CopilotChatBuffer
  q = { "<CMD>lua CopilotChatBuffer()<CR>", "CopilotChat quick chat" },
}
-- toggleterm
lvim.builtin.which_key.mappings["t"] = { "<CMD>ToggleTerm<CR>", "ToggleTerm" }
-- fuzzy motion
lvim.builtin.which_key.mappings["<SPACE>"] = { "<CMD>FuzzyMotion<CR>", "FuzzyMotion" }
-- yankring
lvim.builtin.which_key.mappings["y"] = {
  name = "+Yankring",
  -- YRShow
  h = { "<CMD>YRShow<CR>", "YankRing show" },
}
-- outline
lvim.builtin.which_key.mappings["o"] = { "<CMD>Outline<CR>", "Outline" }
-- lsp
table.insert(lvim.builtin.which_key.mappings["l"], {
  -- todo-comments
  -- TodoLocList
  t = { "<CMD>TodoLocList<CR>", "TodoLocList" },
  -- trouble
  -- Trouble diagnostics toggle
  T = { "<CMD>Trouble diagnostics toggle<CR>", "TroubleDiagnostics" },
})
