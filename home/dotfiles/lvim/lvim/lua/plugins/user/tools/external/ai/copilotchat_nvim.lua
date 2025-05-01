-- github copilot chat for neovim
table.insert(lvim.plugins, {
  "CopilotC-Nvim/CopilotChat.nvim",
  event = "VeryLazy",
  dependencies = {
    "github/copilot.vim",
    "nvim-lua/plenary.nvim",
  },
  branch = "main",
  init = function()
    for _, mode in ipairs({ "n", "x" }) do
      vim.keymap.set(
        mode,
        "<LEADER>Cc",
        "<CMD>CopilotChatCommitStaged<CR>",
        { silent = true, desc = "CopilotChat commit staged" }
      )
      vim.keymap.set(mode, "<LEADER>Cd", "<CMD>CopilotChatDocs<CR>", { silent = true, desc = "CopilotChat docs" })
      vim.keymap.set(mode, "<LEADER>Ce", "<CMD>CopilotChatExplain<CR>", { silent = true, desc = "CopilotChat explain" })
      vim.keymap.set(mode, "<LEADER>Cf", "<CMD>CopilotChatFix<CR>", { silent = true, desc = "CopilotChat fix" })
      vim.keymap.set(mode, "<LEADER>Cl", "<CMD>CopilotChatLoad<CR>", { silent = true, desc = "CopilotChat load" })
      vim.keymap.set(
        mode,
        "<LEADER>Co",
        "<CMD>CopilotChatOptimize<CR>",
        { silent = true, desc = "CopilotChat optimize" }
      )
      vim.keymap.set(
        mode,
        "<LEADER>Cq",
        "<CMD>lua CopilotChatBuffer()<CR>",
        { noremap = true, silent = true, desc = "CopilotChat quick chat" }
      )
      vim.keymap.set(mode, "<LEADER>Cr", "<CMD>CopilotChatReview<CR>", { silent = true, desc = "CopilotChat review" })
      vim.keymap.set(mode, "<LEADER>Cs", "<CMD>CopilotChatSave<CR>", { silent = true, desc = "CopilotChat save" })
      vim.keymap.set(
        mode,
        "<LEADER>Ct",
        "<CMD>CopilotChatToggle<CR>",
        { silent = true, desc = "CopilotChat chat toggle" }
      )
      vim.keymap.set(mode, "<LEADER>CT", "<CMD>CopilotChatTests<CR>", { silent = true, desc = "CopilotChat tests" })
    end
  end,
  opts = {
    system_prompt = require("plugins.user.tools.external.ai.system_prompt").SystemPrompt,
    prompts = {
      Explain = {
        prompt = [[
/COPILOT_GENERATE

選択範囲のコードの説明をしてください。
]],
      },
      Review = {
        prompt = [[
/COPILOT_GENERATE

選択範囲のコードをレビューしてください。
]],
      },
      Fix = {
        prompt = [[
/COPILOT_GENERATE

このコードに問題やバグが無いかレビューしてください。バグやリファクタの余地があればそれを教えてください。
]],
      },
      Optimize = {
        prompt = [[
/COPILOT_GENERATE

このコードをリファクタして、可読性やパフォーマンスをより良くしてください。
]],
      },
      Docs = {
        prompt = [[
/COPILOT_GENERATE

このコードのドキュメントを追記してください。
]],
      },
      Tests = {
        prompt = [[
/COPILOT_GENERATE

このコードに対するテストを追記してください。
]],
      },
      FixDiagnostic = {
        prompt = [[
/COPILOT_GENERATE

このファイル内のDiagnosticについて、解説と修正方法を教えてください。
]],
      },
      Commit = {
        prompt = [[
#git:staged

この変更に対するコミットメッセージを英語で書いてください。タイトルは最大50文字、本文は72文字で折り返されるようにしてください。
タイトルには以下のいずれかを接頭辞として使用してください。タイトルは接頭辞の後にスペースで区切ってください。

- feat:
  - 新機能追加の場合に使用
- fix:
  - バグ修正
- doc:
  - ドキュメントのみの変更の場合に使用
- style:
  - プログラムの動きに影響を与えない変更(インデントの調整やフォーマッタにかけた場合など)
- refactor:
  - バグ修正や新機能追加以外のコード修正の場合に使用
- perf:
  - パフォーマンス改善のためのコード修正の場合に使用
- test:
  - テストの追加や既存テストの修正の場合に使用
- chore:
  - ビルドプロセスやドキュメント生成のような補助ツールやライブラリの変更の場合に使用
- merge:

本文は変更を要点ごとに箇条書きしてください。箇条書きは「- 」で始めてください。
ソースを見ても変更した理由がわからない時は、コミットメッセージを作る前に質問して、その回答も参考にコミットメッセージを生成してください。
また、以下の形式で回答してください。
```
title:
<タイトル>
body:
<本文>
```
]],
      },
    },
    model = "claude-3.7-sonnet",
    selection = function(source)
      return require("CopilotChat.select").visual(source) or require("CopilotChat.select").buffer(source)
    end,
    question_header = "## 👦 You: ",
    answer_header = "## 👧 Senpai: ",
    error_header = "## ❌ Error: ",
    window = {
      layout = "vertical", -- 'vertical', 'horizontal', 'float', 'replace'
      width = 0.5, -- fractional width of parent, or absolute width in columns when > 1
      height = 0.5, -- fractional height of parent, or absolute height in rows when > 1
      -- Options below only apply to floating windows
      relative = "editor", -- 'editor', 'win', 'cursor', 'mouse'
      border = "single", -- 'none', single', 'double', 'rounded', 'solid', 'shadow'
      row = nil, -- row position of the window, default is centered
      col = nil, -- column position of the window, default is centered
      title = "Copilot Chat", -- title of chat window
      footer = nil, -- footer of chat window
      zindex = 1, -- determines if window is on top or below other floating windows
    },
  },
})

function CopilotChatBuffer()
  local input = vim.fn.input("Quick Chat: ")
  if input ~= "" then
    require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
  end
end
