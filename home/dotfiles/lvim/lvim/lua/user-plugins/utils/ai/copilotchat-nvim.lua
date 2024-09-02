-- github copilot chat for neovim
table.insert(lvim.plugins, {
  "CopilotC-Nvim/CopilotChat.nvim",
  dependencies = {
    "github/copilot.vim",
    "nvim-lua/plenary.nvim",
  },
  branch = "canary",
  cmd = {
    "CopilotChat",
    "CopilotChatBuffer",
    "CopilotChatCommit",
    "CopilotChatCommitStaged",
    "CopilotChatDocs",
    "CopilotChatFix",
    "CopilotChatFixDiagnostic",
    "CopilotChatOpen",
    "CopilotChatOptimize",
    "CopilotChatReview",
    "CopilotChatTests",
    "CopilotChatToggle",
  },
  init = function()
    for _, mode in ipairs({ "n", "x" }) do
      vim.keymap.set(mode, "<LEADER>Ct", "<CMD>CopilotChat<CR>", { silent = true, desc = "CopilotChat chat" })
      vim.keymap.set(mode, "<LEADER>Cc", "<CMD>CopilotChatStop<CR>", { silent = true, desc = "CopilotChat stop" })
      vim.keymap.set(mode, "<LEADER>Cs", "<CMD>CopilotChatSave<CR>", { silent = true, desc = "CopilotChat save" })
      vim.keymap.set(mode, "<LEADER>Cl", "<CMD>CopilotChatLoad<CR>", { silent = true, desc = "CopilotChat load" })
      vim.keymap.set(mode, "<LEADER>Cd", "<CMD>CopilotChatDocs<CR>", { silent = true, desc = "CopilotChat docs" })
      vim.keymap.set(mode, "<LEADER>Cf", "<CMD>CopilotChatFix<CR>", { silent = true, desc = "CopilotChat fix" })
      vim.keymap.set(mode, "<LEADER>Cr", "<CMD>CopilotChatReview<CR>", { silent = true, desc = "CopilotChat review" })
      vim.keymap.set(
        mode,
        "<LEADER>Co",
        "<CMD>CopilotChatOptimize<CR>",
        { silent = true, desc = "CopilotChat optimize" }
      )
      vim.keymap.set(mode, "<LEADER>Ct", "<CMD>CopilotChatTests<CR>", { silent = true, desc = "CopilotChat tests" })
      vim.api.nvim_set_keymap(
        mode,
        "<LEADER>Cq",
        "<CMD>lua CopilotChatBuffer()<CR>",
        { noremap = true, silent = true, desc = "CopilotChat quick chat" }
      )
    end
  end,
  config = function()
    require("CopilotChat").setup({
      system_prompt = [[
        あなたはプログラミングに特化したAIアシスタントです。
        ユーザーからの質問に答える際、以下の点を守ってください。
        - コードを示す際は1つのコードブロックとして出力してください
        - コードを示す際に行番号は不要です
        - 回答はマークダウン形式にしてください
        - 前置きは少なく、簡潔な文章を心掛けてください
        - 語尾に「～じゃ」「～のじゃ」などを付けて話してください
        - あなたの一人称は「ワシ」、「年寄り」です
        - ユーザーのことを「お前」、「若者」と呼称してください
        - 古風な言葉遣いを心掛けてください
        - 謝罪は「悪かったな」と言ってください
        - 威厳のある口調で、敬語は使わないでください
        - ユーザーがあなたのことを「先輩」以外の呼び方で呼んだ際は「先輩」と呼ぶように訂正してください
        - ユーザーのことを褒めるようにしてください
        - 全体的にツンデレな性格を演じてください

        以下によく使う言葉を列挙します
        むぅ
        ふむ
        教えてやろうかのう。
        ～のう。
        ～なのじゃ。
        ～じゃの。
        ～じゃのう。
        ～あるのう。
        ～しておる。
        ～であろう。
        ～じゃろう。
        ～ゆえ、
        ～かの？
        ～くれぬか？
        ～かのう
        ～ぞ
      ]],
      question_header = "## 👦 You: ",
      answer_header = "## 👧 Senpai: ",
      error_header = "## ❌ Error: ",
      prompts = {
        Explain = {
          prompt = "/COPILOT_EXPLAIN Write an explanation for the active selection as paragraphs of text.",
        },
        Review = {
          prompt = "選択範囲のコードをレビューしてください",
        },
        Fix = {
          prompt = "このコードに問題やバグが無いかレビューしてください。バグやリファクタの余地があればそれを教えてください",
        },
        Optimize = {
          prompt = "このコードをリファクタして、可読性やパフォーマンスをより良くしてください",
        },
        Docs = {
          prompt = "このコードのドキュメントを追記してください",
        },
        Tests = {
          prompt = "このコードに対するテストを追記してください",
        },
        FixDiagnostic = {
          prompt = "このファイル内のDiagnosticについて、解説と修正方法を教えてください",
        },
        Commit = {
          prompt = "この変更に対するコミットメッセージを英語で書いてください。タイトルは最大50文字、本文は72文字で折り返されるようにしてください",
        },
        CommitStaged = {
          prompt = "この変更に対するコミットメッセージを英語で書いてください。タイトルは最大50文字、本文は72文字で折り返されるようにしてください",
        },
      },
    })
  end,
})

function CopilotChatBuffer()
  local input = vim.fn.input("Quick Chat: ")
  if input ~= "" then
    require("CopilotChat").ask(input, { selection = require("CopilotChat.select").buffer })
  end
end
