-- highlight and search for todo comments
table.insert(lvim.plugins, {
  "folke/todo-comments.nvim",
  event = { "VeryLazy" },
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    signs = true,
    sign_priority = 8,
    keywords = {
      FIX = {
        icon = " ",
        color = "error",
        alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
      },
      TODO = { icon = " ", color = "info" },
      HACK = { icon = " ", color = "warning" },
      WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
      PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
      NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
      TEST = { icon = "⏲ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
    },
    gui_style = {
      fg = "NONE",
      bg = "BOLD",
    },
    merge_keywords = true,

    highlight = {
      multiline = true,
      multiline_pattern = "^.",
      multiline_context = 10,
      before = "",
      keyword = "wide",
      after = "fg",
      pattern = [[.*<(KEYWORDS)\s*:]],
      comments_only = true,
      max_line_len = 400,
      exclude = {},
    },
    colors = {
      error = { "DiagnosticError", "ErrorMsg", "#e67e80" }, -- Everforest red
      warning = { "DiagnosticWarn", "WarningMsg", "#dbbc7f" }, -- Everforest yellow
      info = { "DiagnosticInfo", "#7fbbb3" }, -- Everforest blue
      hint = { "DiagnosticHint", "#83c092" }, -- Everforest sage green
      default = { "Identifier", "#d699b6" }, -- Everforest purple
      test = { "Identifier", "#e69875" }, -- Everforest orange
    },
    search = {
      command = "rg",
      args = {
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
      },
      pattern = [[\b(KEYWORDS):]],
    },
  },
  init = function()
    vim.keymap.set("n", "<LEADER>lt", "<CMD>TodoLocList<CR>", { silent = true, desc = "TodoLocList" })
  end,
})
