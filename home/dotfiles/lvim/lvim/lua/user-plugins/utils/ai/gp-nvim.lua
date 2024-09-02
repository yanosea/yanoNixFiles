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
