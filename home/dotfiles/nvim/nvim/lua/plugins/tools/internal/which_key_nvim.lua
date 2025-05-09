-- popup for key bindings start with <LEADER>
return {
  {
    "folke/which-key.nvim",
    lazy = true,
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        preset = "modern",
        delay = 300,
        sort = { "local", "order", "alphanum", "mod" },
      })
      -- which-key mappings (start with <LEADER>)
      require("which-key").add({
        {
          -- normal and visual
          mode = {"n", "v"},
          -- buffers
          { "<LEADER>b", group = "buffers" },
          { "<LEADER>bb", "<CMD>bprevious<CR>", desc = "switch to previous buffer" },
          { "<LEADER>bc", "<CMD>lua BufferKill()<CR>", desc = "close current buffer" },
          { "<LEADER>bf", "<CMD>Telescope buffers previewer=false<CR>", desc = "find and jump to buffer" },
          { "<LEADER>bj", "<CMD>BufferLinePick<CR>", desc = "jump to buffer" },
          { "<LEADER>bn", "<CMD>bnext<CR>", desc = "switch to next buffer" },
          { "<LEADER>bN", "<CMD>ene!<CR>", desc = "close current buffer" },
          { "<LEADER>bw", "<CMD>w!<CR>", desc = "save buffer" },
          { "<LEADER>c", "<CMD>lua BufferKill()<CR>", desc = "close current buffer" },
          -- explorer
          { "<LEADER>e", "<CMD>NvimTreeToggle<CR>", desc = "explorer" },
          -- find file
          { "<LEADER>f", "<CMD>Telescope find_files<CR>", desc = "find file" },
          -- save
          { "<LEADER>w", "<CMD>w!<CR>", desc = "save buffer" },
          -- quit
          { "<LEADER>q", "<CMD>confirm q<CR>", desc = "quit" },
          -- comment
          { "<LEADER>/", "<Plug>(comment_toggle_linewise_current)", desc = "comment toggle current line" },
          -- dashboard
          { "<LEADER>;", "<CMD>Alpha<CR>", desc = "dashboard" },
        },
        {
          -- visual
          mode = "v",
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

-- mappings = {
--   b = {
--     name = "Buffers",
--     b = { "<CMD>BufferLineCyclePrev<CR>", "previous" },
--     n = { "<CMD>BufferLineCycleNext<CR>", "next" },
--     W = { "<CMD>noautocmd w<CR>", "save without formatting (noautocmd)" },
--     -- w = { "<CMD>BufferWipeout<CR>", "Wipeout" }, -- TODO: implement this for bufferline
--     e = {
--       "<CMD>BufferLinePickClose<CR>",
--       "pick which buffer to close",
--     },
--     h = { "<CMD>BufferLineCloseLeft<CR>", "close all to the left" },
--     l = {
--       "<CMD>BufferLineCloseRight<CR>",
--       "close all to the right",
--     },
--     D = {
--       "<CMD>BufferLineSortByDirectory<CR>",
--       "sort by directory",
--     },
--     L = {
--       "<CMD>BufferLineSortByExtension<CR>",
--       "sort by language",
--     },
--   },
--   d = {
--     name = "Debug",
--     t = { "<CMD>lua require'dap'.toggle_breakpoint()<CR>", "toggle breakpoint" },
--     b = { "<CMD>lua require'dap'.step_back()<CR>", "step back" },
--     c = { "<CMD>lua require'dap'.continue()<CR>", "continue" },
--     C = { "<CMD>lua require'dap'.run_to_cursor()<CR>", "run to cursor" },
--     d = { "<CMD>lua require'dap'.disconnect()<CR>", "disconnect" },
--     g = { "<CMD>lua require'dap'.session()<CR>", "get session" },
--     i = { "<CMD>lua require'dap'.step_into()<CR>", "step into" },
--     o = { "<CMD>lua require'dap'.step_over()<CR>", "step over" },
--     u = { "<CMD>lua require'dap'.step_out()<CR>", "step out" },
--     p = { "<CMD>lua require'dap'.pause()<CR>", "pause" },
--     r = { "<CMD>lua require'dap'.repl.toggle()<CR>", "toggle repl" },
--     s = { "<CMD>lua require'dap'.continue()<CR>", "start" },
--     q = { "<CMD>lua require'dap'.close()<CR>", "quit" },
--     U = { "<CMD>lua require'dapui'.toggle({reset = true})<CR>", "toggle ui" },
--   },
--   p = {
--     name = "Plugins",
--     i = { "<CMD>Lazy install<CR>", "install" },
--     s = { "<CMD>Lazy sync<CR>", "sync" },
--     S = { "<CMD>Lazy clear<CR>", "status" },
--     c = { "<CMD>Lazy clean<CR>", "clean" },
--     u = { "<CMD>Lazy update<CR>", "update" },
--     p = { "<CMD>Lazy profile<CR>", "profile" },
--     l = { "<CMD>Lazy log<CR>", "log" },
--     d = { "<CMD>Lazy debug<CR>", "debug" },
--   },
--
--   -- " Available Debug Adapters:
--   -- "   https://microsoft.github.io/debug-adapter-protocol/implementors/adapters/
--   -- " Adapter configuration and installation instructions:
--   -- "   https://github.com/mfussenegger/nvim-dap/wiki/Debug-Adapter-installation
--   -- " Debug Adapter protocol:
--   -- "   https://microsoft.github.io/debug-adapter-protocol/
--   -- " Debugging
--   g = {
--     name = "Git",
--     -- FIX : g = { "<CMD>lua require 'lvim.core.terminal'.lazygit_toggle()<CR>", "Lazygit" },
--     j = { "<CMD>lua require 'gitsigns'.nav_hunk('next', {navigation_message = false})<CR>", "next hunk" },
--     k = { "<CMD>lua require 'gitsigns'.nav_hunk('prev', {navigation_message = false})<CR>", "prev hunk" },
--     l = { "<CMD>lua require 'gitsigns'.blame_line()<CR>", "blame" },
--     L = { "<CMD>lua require 'gitsigns'.blame_line({full=true})<CR>", "blame line (full)" },
--     p = { "<CMD>lua require 'gitsigns'.preview_hunk()<CR>", "preview hunk" },
--     r = { "<CMD>lua require 'gitsigns'.reset_hunk()<CR>", "reset hunk" },
--     R = { "<CMD>lua require 'gitsigns'.reset_buffer()<CR>", "reset buffer" },
--     s = { "<CMD>lua require 'gitsigns'.stage_hunk()<CR>", "stage hunk" },
--     u = {
--       "<CMD>lua require 'gitsigns'.undo_stage_hunk()<CR>",
--       "undo Stage Hunk",
--     },
--     o = { "<CMD>Telescope git_status<CR>", "open changed file" },
--     b = { "<CMD>Telescope git_branches<CR>", "checkout branch" },
--     c = { "<CMD>Telescope git_commits<CR>", "checkout commit" },
--     C = {
--       "<CMD>Telescope git_bcommits<CR>",
--       "checkout commit(for current file)",
--     },
--     d = {
--       "<CMD>Gitsigns diffthis HEAD<CR>",
--       "git diff",
--     },
--   },
--   l = {
--     name = "LSP",
--     a = { "<CMD>lua vim.lsp.buf.code_action()<CR>", "code action" },
--     d = { "<CMD>Telescope diagnostics bufnr=0 theme=get_ivy<CR>", "buffer diagnostics" },
--     w = { "<CMD>Telescope diagnostics<CR>", "diagnostics" },
--     -- FIX : f = { "<CMD>lua require('lvim.lsp.utils').format()<CR>", "format" },
--     i = { "<CMD>LspInfo<CR>", "info" },
--     I = { "<CMD>Mason<CR>", "mason info" },
--     j = {
--       "<CMD>lua vim.diagnostic.goto_next()<CR>",
--       "next diagnostic",
--     },
--     k = {
--       "<CMD>lua vim.diagnostic.goto_prev()<CR>",
--       "prev diagnostic",
--     },
--     l = { "<CMD>lua vim.lsp.codelens.run()<CR>", "codeLens action" },
--     q = { "<CMD>lua vim.diagnostic.setloclist()<CR>", "quickfix" },
--     r = { "<CMD>lua vim.lsp.buf.rename()<CR>", "rename" },
--     s = { "<CMD>Telescope lsp_document_symbols<CR>", "document symbols" },
--     S = {
--       "<CMD>Telescope lsp_dynamic_workspace_symbols<CR>",
--       "workspace symbols",
--     },
--     e = { "<CMD>Telescope quickfix<CR>", "telescope quickfix" },
--   },
--   s = {
--     name = "Search",
--     b = { "<CMD>Telescope git_branches<CR>", "checkout branch" },
--     c = { "<CMD>Telescope colorscheme<CR>", "colorscheme" },
--     f = { "<CMD>Telescope find_files<CR>", "find file" },
--     h = { "<CMD>Telescope help_tags<CR>", "find help" },
--     H = { "<CMD>Telescope highlights<CR>", "find highlight groups" },
--     M = { "<CMD>Telescope man_pages<CR>", "man pages" },
--     r = { "<CMD>Telescope oldfiles<CR>", "open Recent File" },
--     R = { "<CMD>Telescope registers<CR>", "registers" },
--     t = { "<CMD>Telescope live_grep<CR>", "text" },
--     k = { "<CMD>Telescope keymaps<CR>", "keymaps" },
--     C = { "<CMD>Telescope commands<CR>", "commands" },
--     l = { "<CMD>Telescope resume<CR>", "resume last search" },
--     p = {
--       "<CMD>lua require('telescope.builtin').colorscheme({enable_preview = true})<CR>",
--       "colorscheme with preview",
--     },
--   },
--   T = {
--     name = "treesitter",
--     i = { ":TSConfigInfo<CR>", "info" },
--   },
-- }
