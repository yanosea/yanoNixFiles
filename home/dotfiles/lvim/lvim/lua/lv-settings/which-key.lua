-- which-key.nvim
-- avante
lvim.builtin.which_key.mappings["a"] = {
  name = "+Avante",
  -- Avante
  a = { "<CMD>AvanteAsk<CR>", "AvanteAsk" },
  -- AvanteClear
  C = { "<CMD>AvanteClear<CR>", "AvanteClear" },
  -- AvanteEdit
  e = { "<CMD>AvanteEdit<CR>", "AvanteEdit" },
  -- AvanteFocus
  f = { "<CMD>AvanteFocus<CR>", "AvanteFocus" },
  -- AvanteRefresh
  r = { "<CMD>AvanteRefresh<CR>", "AvanteRefresh" },
  -- AvanteRepoMap
  R = { "<CMD>AvanteRepoMap<CR>", "AvanteRepoMap" },
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
  name = "+LSP",
  -- outline
  -- Outline
  o = { "<CMD>Outline<CR>", "Outline" },
  -- trouble
  -- Trouble diagnostics toggle
  t = { "<CMD>Trouble diagnostics toggle<CR>", "TroubleDiagnostics" },
  -- todo-comments
  -- TodoLocList
  T = { "<CMD>TodoLocList<CR>", "TodoLocList" },
})
-- oil filer
lvim.builtin.which_key.mappings["o"] = { "<CMD>Oil<CR>", "Oil" }
-- toggleterm
lvim.builtin.which_key.mappings["t"] = { "<CMD>ToggleTerm<CR>", "ToggleTerm" }
-- yankring
lvim.builtin.which_key.mappings["y"] = {
  name = "+Yankring",
  -- YRShow
  h = { "<CMD>YRShow<CR>", "YankRing Show" },
}
