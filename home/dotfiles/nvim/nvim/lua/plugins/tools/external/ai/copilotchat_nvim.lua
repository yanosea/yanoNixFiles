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
          "<CMD>CopilotChatCommit<CR>",
          { silent = true, desc = "copilotchat commit" }
        )
        vim.keymap.set(mode, "<LEADER>Cd", "<CMD>CopilotChatDocs<CR>", { silent = true, desc = "copilotchat docs" })
        vim.keymap.set(mode, "<LEADER>Ce", "<CMD>CopilotChatExplain<CR>", { silent = true, desc = "copilotchat explain" })
        vim.keymap.set(mode, "<LEADER>Cf", "<CMD>CopilotChatFix<CR>", { silent = true, desc = "copilotchat fix" })
        vim.keymap.set(mode, "<LEADER>Cl", "<CMD>CopilotChatLoad<CR>", { silent = true, desc = "copilotchat load" })
        vim.keymap.set(
          mode,
          "<LEADER>Co",
          "<CMD>CopilotChatOptimize<CR>",
          { silent = true, desc = "copilotchat optimize" }
        )
        vim.keymap.set(mode, "<LEADER>Cr", "<CMD>CopilotChatReview<CR>", { silent = true, desc = "copilotchat review" })
        vim.keymap.set(mode, "<LEADER>Cs", "<CMD>CopilotChatSave<CR>", { silent = true, desc = "copilotchat save" })
        vim.keymap.set(
          mode,
          "<LEADER>Ct",
          "<CMD>CopilotChatToggle<CR>",
          { silent = true, desc = "copilotchat chat toggle" }
        )
        vim.keymap.set(mode, "<LEADER>CT", "<CMD>CopilotChatTests<CR>", { silent = true, desc = "copilotchat tests" })
      end
    end,
    opts = {
      system_prompt = require("plugins.tools.external.ai.prompts.system_prompt").prompt,
      prompts = {
        Commit = {
          prompt = require("plugins.tools.external.ai.prompts.user_prompts.commit").prompt,
        },
        Docs = {
          prompt = require("plugins.tools.external.ai.prompts.user_prompts.docs").prompt,
        },
        Explain = {
          prompt = require("plugins.tools.external.ai.prompts.user_prompts.explain").prompt,
        },
        Fix = {
          prompt = require("plugins.tools.external.ai.prompts.user_prompts.fix").prompt,
        },
        FixDiagnostic = {
          prompt = require("plugins.tools.external.ai.prompts.user_prompts.fix_diagnostic").prompt,
        },
        Optimize = {
          prompt = require("plugins.tools.external.ai.prompts.user_prompts.optimize").prompt,
        },
        Review = {
          prompt = require("plugins.tools.external.ai.prompts.user_prompts.review").prompt,
        },
        Tests = {
          prompt = require("plugins.tools.external.ai.prompts.user_prompts.tests").prompt,
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
