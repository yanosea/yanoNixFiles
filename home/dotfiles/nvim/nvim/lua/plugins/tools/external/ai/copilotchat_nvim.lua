-- github copilot chat for neovim
return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      "github/copilot.vim",
      "nvim-lua/plenary.nvim",
    },
    lazy = true,
    event = "VeryLazy",
    branch = "main",
    init = function()
      for _, mode in ipairs({ "n", "x" }) do
        vim.keymap.set(
          mode,
          "<LEADER>Cc",
          "<CMD>CopilotChatCommitStaged<CR>",
          { desc = "copilotChat commit staged", silent = true }
        )
        vim.keymap.set(mode, "<LEADER>Cd", "<CMD>CopilotChatDocs<CR>", { desc = "copilotchat docs", silent = true })
        vim.keymap.set(mode, "<LEADER>Ce", "<CMD>CopilotChatExplain<CR>", { desc = "copilotchat explain", silent = true })
        vim.keymap.set(mode, "<LEADER>Cf", "<CMD>CopilotChatFix<CR>", { desc = "copilotchat fix", silent = true })
        vim.keymap.set(mode, "<LEADER>Cl", "<CMD>CopilotChatLoad<CR>", { desc = "copilotchat load", silent = true })
        vim.keymap.set(
          mode,
          "<LEADER>Co",
          "<CMD>CopilotChatOptimize<CR>",
          { desc = "copilotchat optimize", silent = true }
        )
        vim.keymap.set(mode, "<LEADER>Cr", "<CMD>CopilotChatReview<CR>", { desc = "copilotchat review", silent = true })
        vim.keymap.set(mode, "<LEADER>Cs", "<CMD>CopilotChatSave<CR>", { desc = "copilotchat save", silent = true })
        vim.keymap.set(
          mode,
          "<LEADER>Ct",
          "<CMD>CopilotChatToggle<CR>",
          { desc = "copilotchat chat toggle" }
        )
        vim.keymap.set(mode, "<LEADER>CT", "<CMD>CopilotChatTests<CR>", { desc = "copilotchat tests", silent = true })
      end
    end,
    opts = {
      system_prompt = require("plugins.tools.external.ai.prompt.system_prompt").SystemPrompt,
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
  },
}
