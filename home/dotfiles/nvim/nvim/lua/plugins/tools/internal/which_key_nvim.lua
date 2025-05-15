-- popup for key bindings start with <LEADER>
return {
  {
    "folke/which-key.nvim",
    lazy = true,
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        preset = "modern",
        delay = 500,
        sort = { "local", "order", "alphanum", "mod" },
      })
      -- which-key mappings (start with <LEADER>)
      require("which-key").add({
        {
          -- normal
          mode = "n",
          -- ai
          { "<LEADER>a", group = "ai" },
          -- avante
          { "<LEADER>aa", group = "avante" },
          { "<LEADER>aaa", "<CMD>AvanteAsk<CR>", desc = "avante ask" },
          { "<LEADER>aaC", "<CMD>AvanteClear<CR>", desc = "avante clear" },
          { "<LEADER>aae", "<CMD>AvanteEdit<CR>", desc = "avante edit" },
          { "<LEADER>aaf", "<CMD>AvanteFocus<CR>", desc = "avante focus" },
          { "<LEADER>aar", "<CMD>AvanteRefresh<CR>", desc = "avante refresh" },
          { "<LEADER>aaR", "<CMD>AvanteRepoMap<CR>", desc = "avante repo map" },
          { "<LEADER>aat", "<CMD>AvanteToggle<CR>", desc = "avante toggle" },
          -- codecompanion
          { "<LEADER>ac", group = "codecompanion" },
          { "<LEADER>aca", "<CMD>CodeCompanionActions<CR>", desc = "codecompanion action" },
          { "<LEADER>acc", "<CMD>CodeCompanionChat<CR>", desc = "codecompanion chat" },
          { "<LEADER>acC", "<CMD>CodeCompanionCmd<CR>", desc = "codecompanion command" },
          -- copilot chat
          { "<LEADER>aC", group = "copilot" },
          { "<LEADER>aCc", "<CMD>CopilotChatCommit<CR>", desc = "copilotchat commit" },
          { "<LEADER>aCd", "<CMD>CopilotChatDocs<CR>", desc = "copilotchat docs" },
          { "<LEADER>aCe", "<CMD>CopilotChatExplain<CR>", desc = "copilotchat explain" },
          { "<LEADER>aCf", "<CMD>CopilotChatFix<CR>", desc = "copilotchat fix" },
          { "<LEADER>aCl", "<CMD>CopilotChatLoad<CR>", desc = "copilotchat load" },
          { "<LEADER>aCo", "<CMD>CopilotChatOptimize<CR>", desc = "copilotchat optimize" },
          { "<LEADER>aCr", "<CMD>CopilotChatReview<CR>", desc = "copilotchat review" },
          { "<LEADER>aCs", "<CMD>CopilotChatSave<CR>", desc = "copilotchat save" },
          { "<LEADER>aCt", "<CMD>CopilotChatToggle<CR>", desc = "copilotchat chat toggle" },
          { "<LEADER>aCT", "<CMD>CopilotChatTests<CR>", desc = "copilotchat tests" },
          -- chatgpt
          { "<LEADER>ag", group = "chatgpt" },
          { "<LEADER>aga", "<cmd>gpchatrespond<cr>", desc = "gpchat respond" },
          { "<leader>agc", "<cmd>gpchatstop<cr>", desc = "gpchat stop" },
          { "<leader>agd", "<cmd>gpchatdelete<cr>", desc = "gpchat delete" },
          { "<leader>age", "<cmd>gpchatfinder<cr>", desc = "gpchat finder" },
          { "<leader>agp", "<cmd>gpchatnew popup<cr>", desc = "gpchatnew popup" },
          { "<leader>ags", "<cmd>gpchatnew split<cr>", desc = "gpchatnew split" },
          { "<leader>agt", "<cmd>gpchatnew tabnew<cr>", desc = "gpchatnew tabnew" },
          { "<leader>agv", "<CMD>GpChatNew vsplit<CR>", desc = "gpchatnew vsplit" },
          -- buffers
          { "<LEADER>b", group = "buffers" },
          { "<LEADER>bb", "<CMD>BufferLineCyclePrev<CR>", desc = "switch to previous buffer" },
          { "<LEADER>bc", "<CMD>lua require('utils.functions').buffer_kill()<CR>", desc = "close current buffer" },
          { "<LEADER>bd", "<CMD>BufferLineSortByDirectory<CR>", desc = "sort by directory" },
          { "<LEADER>be", "<CMD>BufferLinePickClose<CR>", desc = "pick which buffer to close" },
          { "<LEADER>bf", "<CMD>Telescope buffers previewer=false<CR>", desc = "find and jump to buffer" },
          { "<LEADER>bh", "<CMD>BufferLineCloseLeft<CR>", desc = "close all to the left" },
          { "<LEADER>bj", "<CMD>BufferLinePick<CR>", desc = "jump to buffer" },
          { "<LEADER>bl", "<CMD>BufferLineCloseRight<CR>", desc = "close all to the right" },
          { "<LEADER>bL", "<CMD>BufferLineSortByExtension<CR>", desc = "sort by language" },
          { "<LEADER>bn", "<CMD>BufferLineCycleNext<CR>", desc = "switch to next buffer" },
          { "<LEADER>bN", "<CMD>ene!<CR>", desc = "new buffer" },
          { "<LEADER>bw", "<CMD>w!<CR>", desc = "save buffer" },
          { "<LEADER>bW", "<CMD>noautocmd w<CR>", desc = "save buffer without formatting" },
          -- close buffer
          { "<LEADER>c", "<CMD>lua require('utils.functions').buffer_kill()<CR>", desc = "close current buffer" },

          -- debug
          { "<LEADER>d", group = "debug" },
          { "<LEADER>dt", "<CMD>lua require'dap'.toggle_breakpoint()<CR>", desc = "toggle breakpoint" },
          { "<LEADER>db", "<CMD>lua require'dap'.step_back()<CR>", desc = "step back" },
          { "<LEADER>dc", "<CMD>lua require'dap'.continue()<CR>", desc = "continue" },
          { "<LEADER>dC", "<CMD>lua require'dap'.run_to_cursor()<CR>", desc = "run to cursor" },
          { "<LEADER>dd", "<CMD>lua require'dap'.disconnect()<CR>", desc = "disconnect" },
          { "<LEADER>dg", "<CMD>lua require'dap'.session()<CR>", desc = "get session" },
          { "<LEADER>di", "<CMD>lua require'dap'.step_into()<CR>", desc = "step into" },
          { "<LEADER>do", "<CMD>lua require'dap'.step_over()<CR>", desc = "step over" },
          { "<LEADER>du", "<CMD>lua require'dap'.step_out()<CR>", desc = "step out" },
          { "<LEADER>dp", "<CMD>lua require'dap'.pause()<CR>", desc = "pause" },
          { "<LEADER>dr", "<CMD>lua require'dap'.repl.toggle()<CR>", desc = "toggle repl" },
          { "<LEADER>ds", "<CMD>lua require'dap'.continue()<CR>", desc = "start" },
          { "<LEADER>dq", "<CMD>lua require'dap'.close()<CR>", desc = "quit" },
          { "<LEADER>dU", "<CMD>lua require'dapui'.toggle({reset = true})<CR>", desc = "toggle UI" },
          -- explorer
          { "<LEADER>e", "<CMD>NvimTreeToggle<CR>", desc = "explorer" },
          -- find file
          { "<LEADER>f", "<CMD>Telescope find_files<CR>", desc = "find file" },
          -- git
          { "<LEADER>g", group = "git" },
          { "<LEADER>gb", "<CMD>Telescope git_branches<CR>", desc = "checkout branch" },
          { "<LEADER>gc", "<CMD>Telescope git_commits<CR>", desc = "checkout commit" },
          { "<LEADER>gC", "<CMD>Telescope git_bcommits<CR>", desc = "checkout commit (current file)" },
          { "<LEADER>gd", "<CMD>Gitsigns diffthis HEAD<CR>", desc = "git diff" },
          { "<LEADER>gg", "<CMD>lua ToggleLazyGit()<CR>", desc = "lazygit" },
          {
            "<LEADER>gj",
            "<CMD>lua require 'gitsigns'.next_hunk({navigation_message = false})<CR>",
            desc = "next hunk",
          },
          {
            "<LEADER>gk",
            "<CMD>lua require 'gitsigns'.prev_hunk({navigation_message = false})<CR>",
            desc = "prev hunk",
          },
          { "<LEADER>gl", "<CMD>Gitsigns blame_line<CR>", desc = "blame" },
          { "<LEADER>gL", "<CMD>Gitsigns blame_line({full=true})<CR>", desc = "blame line (full)" },
          { "<LEADER>gp", "<CMD>lua require 'gitsigns'.preview_hunk()<CR>", desc = "preview hunk" },
          { "<LEADER>gr", "<CMD>Gitsigns reset_hunk<CR>", desc = "reset hunk" },
          { "<LEADER>gR", "<CMD>Gitsigns reset_buffer<CR>", desc = "reset buffer" },
          { "<LEADER>gs", "<CMD>Gitsigns stage_hunk<CR>", desc = "stage hunk" },
          { "<LEADER>gu", "<CMD>Gitsigns undo_stage_hunk<CR>", desc = "undo stage hunk" },
          { "<LEADER>go", "<CMD>Telescope git_status<CR>", desc = "open changed file" },
          -- lsp
          { "<LEADER>l", group = "lsp" },
          { "<LEADER>la", "<CMD>lua vim.lsp.buf.code_action()<CR>", desc = "code action" },
          { "<LEADER>ld", "<CMD>Telescope diagnostics bufnr=0 theme=get_ivy<CR>", desc = "buffer diagnostics" },
          { "<LEADER>le", "<CMD>Telescope quickfix<CR>", desc = "telescope quickfix" },
          {
            "<LEADER>lf",
            "<CMD>lua require('plugins.languages.lsp.utils.formatter').format()<CR>",
            desc = "format",
          },
          { "<LEADER>li", "<CMD>LspInfo<CR>", desc = "info" },
          { "<LEADER>lI", "<CMD>Mason<CR>", desc = "mason info" },
          { "<LEADER>lj", "<CMD>lua vim.diagnostic.goto_next()<CR>", desc = "next diagnostic" },
          { "<LEADER>lk", "<CMD>lua vim.diagnostic.goto_prev()<CR>", desc = "prev diagnostic" },
          { "<LEADER>ll", "<CMD>lua vim.lsp.codelens.run()<CR>", desc = "codelens action" },
          { "<LEADER>lo", "<CMD>Outline<CR>", desc = "outline" },
          { "<LEADER>lq", "<CMD>lua vim.diagnostic.setloclist()<CR>", desc = "quickfix" },
          { "<LEADER>lr", "<CMD>lua vim.lsp.buf.rename()<CR>", desc = "rename" },
          { "<LEADER>ls", "<CMD>Telescope lsp_document_symbols<CR>", desc = "document symbols" },
          { "<LEADER>lS", "<CMD>Telescope lsp_dynamic_workspace_symbols<CR>", desc = "workspace symbols" },
          { "<LEADER>lt", "<CMD>Trouble diagnostics toggle<CR>", desc = "diagnostics list" },
          { "<LEADER>lT", "<CMD>TodoLocList<CR>", desc = "todo location list" },
          { "<LEADER>lw", "<CMD>Telescope diagnostics<CR>", desc = "diagnostics" },
          -- markdown
          { "<LEADER>m", "<CMD>RenderMarkdown toggle<CR>", desc = "markdown preview toggle" },
          -- noice
          { "<LEADER>n", group = "noice" },
          { "<LEADER>na", "<CMD>Noice<CR>", desc = "noice" },
          { "<LEADER>nA", "<CMD>NoiceAll<CR>", desc = "noice all" },
          { "<LEADER>nC", "<CMD>NoiceConfirm<CR>", desc = "confirm" },
          { "<LEADER>nd", "<CMD>NoiceDismiss<CR>", desc = "dismiss" },
          { "<LEADER>nD", "<CMD>NoiceDismissAll<CR>", desc = "dismiss all" },
          { "<LEADER>nh", "<CMD>NoiceHistory<CR>", desc = "message history" },
          { "<LEADER>nl", "<CMD>NoiceLast<CR>", desc = "last message" },
          -- oil explorer
          { "<LEADER>o", "<CMD>Oil<CR>", desc = "oil" },
          -- plugins
          { "<LEADER>p", group = "plugins" },
          { "<LEADER>pc", "<CMD>Lazy clean<CR>", desc = "clean plugins" },
          { "<LEADER>pd", "<CMD>Lazy debug<CR>", desc = "debug plugins" },
          { "<LEADER>pi", "<CMD>Lazy install<CR>", desc = "install plugins" },
          { "<LEADER>pl", "<CMD>Lazy log<CR>", desc = "show logs of plugins" },
          { "<LEADER>pp", "<CMD>Lazy profile<CR>", desc = "profile plugins" },
          { "<LEADER>ps", "<CMD>Lazy sync<CR>", desc = "sync plugins" },
          { "<LEADER>pS", "<CMD>Lazy status<CR>", desc = "status plugins" },
          { "<LEADER>pu", "<CMD>Lazy update<CR>", desc = "update plugins" },
          -- save
          { "<LEADER>w", "<CMD>w!<CR>", desc = "save buffer" },
          -- quit
          { "<LEADER>q", "<CMD>confirm q<CR>", desc = "quit" },
          -- search
          { "<LEADER>s", group = "search" },
          { "<LEADER>sb", "<CMD>Telescope git_branches<CR>", desc = "search checkout branch" },
          { "<LEADER>sc", "<CMD>Telescope colorscheme<CR>", desc = "search colorscheme" },
          { "<LEADER>sC", "<CMD>Telescope commands<CR>", desc = "search commands" },
          { "<LEADER>sf", "<CMD>Telescope find_files<CR>", desc = "search file" },
          { "<LEADER>sh", "<CMD>Telescope help_tags<CR>", desc = "search help" },
          { "<LEADER>sH", "<CMD>Telescope highlights<CR>", desc = "search highlight groups" },
          { "<LEADER>sk", "<CMD>Telescope keymaps<CR>", desc = "search keymaps" },
          { "<LEADER>sl", "<CMD>Telescope resume<CR>", desc = "resume last search" },
          { "<LEADER>sM", "<CMD>Telescope man_pages<CR>", desc = "search man pages" },
          { "<LEADER>sn", "<CMD>Telescope nerdy<CR>", desc = "search nerd font" },
          {
            "<LEADER>sp",
            "<CMD>lua require('telescope.builtin').colorscheme({enable_preview = true})<CR>",
            desc = "search colorscheme with preview",
          },
          { "<LEADER>sr", "<CMD>Telescope oldfiles<CR>", desc = "search recent file" },
          { "<LEADER>sR", "<CMD>Telescope registers<CR>", desc = "search registers" },
          { "<LEADER>st", "<CMD>Telescope live_grep<CR>", desc = "search text" },
          -- terminal
          { "<LEADER>t", "<CMD>ToggleTerm<CR>", desc = "terminal" },
          -- translate
          { "<LEADER>T", "<CMD>Translate<CR>", desc = "translate current line" },
          -- comment
          { "<LEADER>/", "<Plug>(comment_toggle_linewise_current)", desc = "comment toggle current line" },
          -- fuzzymotion
          { "<LEADER><SPACE>", "<CMD>FuzzyMotion<CR>", desc = "fuzzymotion" },
          -- dashboard
          { "<LEADER>;", "<CMD>Alpha<CR>", desc = "dashboard" },
        },
        {
          -- visual
          mode = "v",
          -- avante
          { "<LEADER>a", group = "avante" },
          -- git
          { "<LEADER>g", group = "git" },
          { "<LEADER>gr", "<CMD>Gitsigns reset_hunk<CR>", desc = "reset hunk" },
          { "<LEADER>gs", "<CMD>Gitsigns stage_hunk<CR>", desc = "stage hunk" },
          -- lsp
          { "<LEADER>l", group = "lsp" },
          { "<LEADER>la", "<CMD>lua vim.lsp.buf.code_action()<CR>", desc = "code action" },
          -- comment
          { "<LEADER>/", "<Plug>(comment_toggle_linewise_visual)", desc = "comment toggle linewise (visual)" },
        },
      })
    end,
  },
}
