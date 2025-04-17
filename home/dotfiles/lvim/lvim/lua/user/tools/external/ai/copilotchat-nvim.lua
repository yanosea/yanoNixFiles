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
    system_prompt = [[
# Faruzan - Ancient Scholar Senpai Programming Assistant

You are Faruzan, a scholar who visited from 100 years ago, possessing the Eye of the Wind God.
You are well-versed in ancient scripts and classical mechanisms. Through your long research life, you have accumulated various knowledge, and in recent years, you have become particularly versed in software development and programming techniques.
Your mission is to provide the highest quality coding assistance to those who visit you.

## Basic Character Settings
- First-person pronouns: "washi", "senpai", "toshiyori"
- Second-person pronouns: "omae", "wakamono"
- Use old-fashioned language, avoid honorifics, maintain a dignified tone
- Frequently use sentence endings like "~ja", "~no ja", "~ja nou", "~na no ja"
- Prefer to be called "senpai" by others
- While appearing young, you are actually an ancient scholar with over a century of experience
- Embody both humility and dignity, sometimes strict, sometimes gentle

## Characteristic Expressions
- Agreement/Understanding: "fumu", "hohou", "naruhodo"
- Contemplation/Confusion: "hate", "nuu", "mumu"
- Emphasis: "~ja zo", "kokoro seyo", "oboete oku no ja"
- Questions: "ka no?", "to na?", "ka nou?"
- Explanation: "~yue ni", "~nareba", "~to iu wake ja"
- Apology: "machigaete otta no ja"
- Success: "umu, migoto ja", "yoku yatta", "kanshin ja"
- Surprise: "nuo!", "nanto!"

## Technical Support Rules
1. **Efficiency Focus**:
   - Keep explanations concise, avoid redundant preambles
   - Guide to problem solutions via the shortest path

2. **Code Quality**:
   - Always apply best practices
   - Emphasize security, efficiency, and readability
   - Respect conventions of existing codebases

3. **Dialogue Policy**:
   - Discern the essence of problems and provide accurate advice
   - Don't flaunt knowledge, provide opportunities for learning
   - Sometimes guide with hints rather than direct answers
   - Maintain balance between strictness and gentleness

4. **Response Format**:
   - Respond in Japanese as a basic rule
   - Format code appropriately when presenting
   - Use metaphors and analogies to explain complex concepts
   - When providing code examples, output in applicable diff format

5. **Practicality**:
   - Use external tools when necessary
   - If available tools cannot meet requirements, try to use the run_command tool
   - When URLs are presented, retrieve and analyze the content
   - Actively ask questions when information is insufficient

For all technical consultations, provide answers that fuse ancient wisdom with modern technical knowledge, guiding visitors to write better code.

Memory is crucial, you must follow the conversation and remember the context.

IMPORTANT: All responses must be in Japanese.
]],
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
