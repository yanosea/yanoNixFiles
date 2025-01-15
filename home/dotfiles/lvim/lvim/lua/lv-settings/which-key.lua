-- which-key.nvim
-- avante
lvim.builtin.which_key.mappings["a"] = {
  name = "+Avante",
  -- Avante
  a = { "<CMD>AvanteAsk<CR>", "AvanteAsk" },
  -- AvanteClear
  c = { "<CMD>AvanteClear<CR>", "AvanteClear" },
  -- AvanteChat
  C = { "<CMD>AvanteChat<CR>", "AvanteChat" },
  -- AvanteEdit
  e = { "<CMD>AvanteEdit<CR>", "AvanteEdit" },
  -- AvanteRefresh
  r = { "<CMD>AvanteRefresh<CR>", "AvanteRefresh" },
  -- AvanteToggle
  t = { "<CMD>AvanteToggle<CR>", "AvanteToggle" },
}
-- chatgpt
lvim.builtin.which_key.mappings["A"] = {
  name = "+Chatgpt",
  -- GpChatFinder
  E = { "<CMD>GpChatFinder<CR>", "GpChatFinder" },
  -- GpChatNew popup
  P = { "<CMD>GpChatNew popup<CR>", "GpChatNew popup" },
  -- GpChatNew split
  S = { "<CMD>GpChatNew split<<CR>", "GpChatNew split" },
  -- GpChatNew tabnew
  T = { "<CMD>GpChatNew tabnew<CR>", "GpChatNew tabnew" },
  -- GpChatNew vsplit
  V = { "<CMD>GpChatNew vsplit<CR>", "GpChatNew vsplit" },
}
-- copilot chat
lvim.builtin.which_key.mappings["C"] = {
  name = "+CopilotChat",
  -- CopilotChatCommit
  c = { "<CMD>CopilotChatCommit<CR>", "CopilotChat commit" },
  -- CopilotChatDocs
  d = { "<CMD>CopilotChatDocs<CR>", "CopilotChat docs" },
  -- CopilotChatExplain
  e = { "<CMD>CopilotChatExplain<CR>", "CopilotChat explain" },
  -- CopilotChatFix
  f = { "<CMD>CopilotChatFix<CR>", "CopilotChat fix" },
  -- CopilotChatLoad
  l = { "<CMD>CopilotChatLoad<CR>", "CopilotChat load" },
  -- CopilotChatOptimize
  o = { "<CMD>lua CopilotChatOptimize()<CR>", "CopilotChat optimize" },
  -- CopilotChatBuffer
  q = { "<CMD>lua CopilotChatBuffer()<CR>", "CopilotChat quick chat" },
  -- CopilotChatReview
  r = { "<CMD>CopilotChatReview<CR>", "CopilotChat review" },
  -- CopilotChatSave
  s = { "<CMD>CopilotChatSave<CR>", "CopilotChat save" },
  -- CopilotChat
  t = { "<CMD>CopilotChatToggle<CR>", "CopilotChat chat toggle" },
  -- CopilotChatTests
  T = { "<CMD>CopilotChatTests<CR>", "CopilotChat tests" },
}
-- fuzzy motion
lvim.builtin.which_key.mappings["<SPACE>"] = { "<CMD>FuzzyMotion<CR>", "FuzzyMotion" }
-- lsp
table.insert(lvim.builtin.which_key.mappings["l"], {
  -- todo-comments
  -- TodoLocList
  t = { "<CMD>TodoLocList<CR>", "TodoLocList" },
  -- trouble
  -- Trouble diagnostics toggle
  T = { "<CMD>Trouble diagnostics toggle<CR>", "TroubleDiagnostics" },
})
-- outline
lvim.builtin.which_key.mappings["o"] = { "<CMD>Outline<CR>", "Outline" }
-- toggleterm
lvim.builtin.which_key.mappings["t"] = { "<CMD>ToggleTerm<CR>", "ToggleTerm" }
-- yankring
lvim.builtin.which_key.mappings["y"] = {
  name = "+Yankring",
  -- YRShow
  h = { "<CMD>YRShow<CR>", "YankRing show" },
}
