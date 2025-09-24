-- popup for key bindings start with <LEADER>
return {
	{
		"folke/which-key.nvim",
		lazy = true,
		event = "VeryLazy",
		config = function()
			-- which-key.nvim config
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
					{ "<LEADER>at", "<CMD>Aibo -opener=vsplit claude<CR>", desc = "ai: toggle chat" },
					-- buffers
					{ "<LEADER>b", group = "buffers" },
					{ "<LEADER>bb", "<CMD>BufferLineCyclePrev<CR>", desc = "buffer: switch to previous" },
					{
						"<LEADER>bc",
						"<CMD>lua require('utils.functions').buffer_kill()<CR>",
						desc = "buffer: close current",
					},
					{ "<LEADER>bd", "<CMD>BufferLineSortByDirectory<CR>", desc = "sort by directory" },
					{ "<LEADER>be", "<CMD>BufferLinePickClose<CR>", desc = "buffer: pick which to close" },
					{ "<LEADER>bf", "<CMD>Telescope buffers previewer=false<CR>", desc = "buffer: find and jump to" },
					{ "<LEADER>bh", "<CMD>BufferLineCloseLeft<CR>", desc = "buffer: close all to the left" },
					{ "<LEADER>bj", "<CMD>BufferLinePick<CR>", desc = "buffer: jump to" },
					{ "<LEADER>bl", "<CMD>BufferLineCloseRight<CR>", desc = "buffer: close all to the right" },
					{ "<LEADER>bL", "<CMD>BufferLineSortByExtension<CR>", desc = "buffer: sort by language" },
					{ "<LEADER>bn", "<CMD>BufferLineCycleNext<CR>", desc = "buffer: switch to next" },
					{ "<LEADER>bN", "<CMD>ene!<CR>", desc = "buffer: new" },
					{ "<LEADER>bp", "<CMD>BufferLineTogglePin<CR>", desc = "buffer: toggle pin" },
					{ "<LEADER>bw", "<CMD>w!<CR>", desc = "buffer: save" },
					{ "<LEADER>bW", "<CMD>noautocmd w<CR>", desc = "buffer: save without formatting" },
					-- close buffer
					{
						"<LEADER>c",
						"<CMD>lua require('utils.functions').buffer_kill()<CR>",
						desc = "close current buffer",
					},
					-- debug
					{ "<LEADER>d", group = "debug" },
					{
						"<LEADER>dt",
						"<CMD>lua require'dap'.toggle_breakpoint()<CR>",
						desc = "debug: toggle breakpoint",
					},
					{ "<LEADER>db", "<CMD>lua require'dap'.step_back()<CR>", desc = "debug: step back" },
					{ "<LEADER>dc", "<CMD>lua require'dap'.continue()<CR>", desc = "debug: continue" },
					{ "<LEADER>dC", "<CMD>lua require'dap'.run_to_cursor()<CR>", desc = "debug: run to cursor" },
					{ "<LEADER>dd", "<CMD>lua require'dap'.disconnect()<CR>", desc = "debug: disconnect" },
					{ "<LEADER>dg", "<CMD>lua require'dap'.session()<CR>", desc = "debug: get session" },
					{ "<LEADER>di", "<CMD>lua require'dap'.step_into()<CR>", desc = "debug: step into" },
					{ "<LEADER>do", "<CMD>lua require'dap'.step_over()<CR>", desc = "debug: step over" },
					{ "<LEADER>dp", "<CMD>lua require'dap'.pause()<CR>", desc = "debug: pause" },
					{ "<LEADER>dq", "<CMD>lua require'dap'.close()<CR>", desc = "debug: quit" },
					{ "<LEADER>dr", "<CMD>lua require'dap'.repl.toggle()<CR>", desc = "debug: toggle repl" },
					{ "<LEADER>ds", "<CMD>lua require'dap'.continue()<CR>", desc = "debug: start" },
					{ "<LEADER>du", "<CMD>lua require'dap'.step_out()<CR>", desc = "debug: step out" },
					{ "<LEADER>dU", "<CMD>lua require'dapui'.toggle({reset = true})<CR>", desc = "debug: toggle ui" },
					-- explorer
					{ "<LEADER>e", "<CMD>NvimTreeToggle<CR>", desc = "explorer" },
					-- find file
					{ "<LEADER>f", "<CMD>Telescope find_files<CR>", desc = "find file" },
					-- git
					{ "<LEADER>g", group = "git" },
					{ "<LEADER>gb", "<CMD>Telescope git_branches<CR>", desc = "git: checkout branch" },
					{ "<LEADER>gc", "<CMD>Telescope git_commits<CR>", desc = "git: checkout commit" },
					{ "<LEADER>gC", "<CMD>Telescope git_bcommits<CR>", desc = "git: checkout commit (current file)" },
					{ "<LEADER>gd", "<CMD>Gitsigns diffthis HEAD<CR>", desc = "git: git diff" },
					{ "<LEADER>gg", "<CMD>lua ToggleLazyGit()<CR>", desc = "git: lazygit" },
					{
						"<LEADER>gj",
						"<CMD>lua require 'gitsigns'.next_hunk({navigation_message = false})<CR>",
						desc = "git: next hunk",
					},
					{
						"<LEADER>gk",
						"<CMD>lua require 'gitsigns'.prev_hunk({navigation_message = false})<CR>",
						desc = "git: prev hunk",
					},
					{ "<LEADER>gl", "<CMD>Gitsigns blame_line<CR>", desc = "git: blame" },
					{ "<LEADER>gL", "<CMD>Gitsigns blame_line({full=true})<CR>", desc = "git: blame line (full)" },
					{ "<LEADER>go", "<CMD>Telescope git_status<CR>", desc = "git: open changed file" },
					{ "<LEADER>gp", "<CMD>lua require 'gitsigns'.preview_hunk()<CR>", desc = "git: preview hunk" },
					{ "<LEADER>gr", "<CMD>Gitsigns reset_hunk<CR>", desc = "git: reset hunk" },
					{ "<LEADER>gR", "<CMD>Gitsigns reset_buffer<CR>", desc = "git: reset buffer" },
					{ "<LEADER>gs", "<CMD>Gitsigns stage_hunk<CR>", desc = "git: stage hunk" },
					{ "<LEADER>gu", "<CMD>Gitsigns undo_stage_hunk<CR>", desc = "git: undo stage hunk" },
					{ "<LEADER>gU", "<CMD>OpenGitHubUrlUnderCursor<CR>", desc = "git: open github url" },
					-- grug far
					{ "<LEADER>G", "<CMD>GrugFar<CR>", desc = "grug far: search and replace text" },
					-- hardtime
					{ "<LEADER>H", "<CMD>Hardtime toggle<CR>", desc = "hardtime: toggle" },
					-- lsp
					{ "<LEADER>l", group = "lsp" },
					{ "<LEADER>la", "<CMD>lua vim.lsp.buf.code_action()<CR>", desc = "lsp: code action" },
					{
						"<LEADER>ld",
						"<CMD>Telescope diagnostics bufnr=0 theme=get_ivy<CR>",
						desc = "lsp: buffer diagnostics",
					},
					{ "<LEADER>le", "<CMD>Telescope quickfix<CR>", desc = "lsp: telescope quickfix" },
					{
						"<LEADER>lf",
						"<CMD>lua require('plugins.languages.lsp.utils.formatter').format()<CR>",
						desc = "lsp: format",
					},
					{ "<LEADER>li", "<CMD>LspInfo<CR>", desc = "lsp: info" },
					{ "<LEADER>lI", "<CMD>Mason<CR>", desc = "lsp: mason info" },
					{ "<LEADER>lj", "<CMD>lua vim.diagnostic.goto_next()<CR>", desc = "lsp: next diagnostic" },
					{ "<LEADER>lk", "<CMD>lua vim.diagnostic.goto_prev()<CR>", desc = "lsp: prev diagnostic" },
					{ "<LEADER>ll", "<CMD>lua vim.lsp.codelens.run()<CR>", desc = "lsp: codelens action" },
					{ "<LEADER>lo", "<CMD>Outline<CR>", desc = "lsp: outline" },
					{ "<LEADER>lq", "<CMD>lua vim.diagnostic.setloclist()<CR>", desc = "lsp: quickfix" },
					{ "<LEADER>lr", "<CMD>lua vim.lsp.buf.rename()<CR>", desc = "lsp: rename" },
					{ "<LEADER>ls", "<CMD>Telescope lsp_document_symbols<CR>", desc = "lsp: document symbols" },
					{
						"<LEADER>lS",
						"<CMD>Telescope lsp_dynamic_workspace_symbols<CR>",
						desc = "lsp: workspace symbols",
					},
					{ "<LEADER>lt", "<CMD>Trouble diagnostics toggle<CR>", desc = "lsp: diagnostics list" },
					{ "<LEADER>lT", "<CMD>TodoLocList<CR>", desc = "lsp: todo location list" },
					{ "<LEADER>lw", "<CMD>Telescope diagnostics<CR>", desc = "lsp: diagnostics" },
					-- markdown
					{ "<LEADER>m", group = "markdown" },
					{ "<LEADER>mp", "<CMD>PeekOpen<CR>", desc = "markdown: preview in browser" },
					{ "<LEADER>mt", "<CMD>RenderMarkdown toggle<CR>", desc = "markdown: preview toggle" },
					-- noice
					{ "<LEADER>n", group = "noice" },
					{ "<LEADER>na", "<CMD>NoiceAll<CR>", desc = "noice: all" },
					{ "<LEADER>nC", "<CMD>NoiceConfirm<CR>", desc = "noice: confirm" },
					{ "<LEADER>nd", "<CMD>NoiceDismiss<CR>", desc = "noice: dismiss" },
					{ "<LEADER>nD", "<CMD>NoiceDismissAll<CR>", desc = "noice: dismiss all" },
					{ "<LEADER>nh", "<CMD>NoiceHistory<CR>", desc = "noice: message history" },
					{ "<LEADER>nl", "<CMD>NoiceLast<CR>", desc = "noice: last message" },
					{ "<LEADER>ns", "<CMD>Noice<CR>", desc = "noice: show" },
					-- org mode (for grouping)
					{ "<LEADER>o", group = "orgmode" },
					-- oil explorer
					{ "<LEADER>O", "<CMD>Oil<CR>", desc = "oil" },
					-- plugins
					{ "<LEADER>p", group = "plugins" },
					{ "<LEADER>pc", "<CMD>Lazy clean<CR>", desc = "plugins: clean" },
					{ "<LEADER>pd", "<CMD>Lazy debug<CR>", desc = "plugins: debug" },
					{ "<LEADER>pi", "<CMD>Lazy install<CR>", desc = "plugins: install" },
					{ "<LEADER>pl", "<CMD>Lazy log<CR>", desc = "plugins: commit logs" },
					{ "<LEADER>pp", "<CMD>Lazy profile<CR>", desc = "plugins: profile" },
					{ "<LEADER>ps", "<CMD>Lazy sync<CR>", desc = "plugins: sync" },
					{ "<LEADER>pS", "<CMD>Lazy status<CR>", desc = "plugins: status" },
					{ "<LEADER>pu", "<CMD>Lazy update<CR>", desc = "plugins: update" },
					-- save
					{ "<LEADER>w", "<CMD>w!<CR>", desc = "save buffer" },
					-- quit
					{ "<LEADER>q", "<CMD>confirm q<CR>", desc = "quit" },
					-- reader mode
					{ "<LEADER>R", "<CMD>ReaderMode<CR>", desc = "reader mode: toggle" },
					-- search
					{ "<LEADER>s", group = "search" },
					{ "<LEADER>sb", "<CMD>Telescope git_branches<CR>", desc = "search: checkout branch" },
					{ "<LEADER>sc", "<CMD>Telescope colorscheme<CR>", desc = "search: colorscheme" },
					{ "<LEADER>sC", "<CMD>Telescope commands<CR>", desc = "search: commands" },
					{ "<LEADER>sf", "<CMD>Telescope find_files<CR>", desc = "search: file" },
					{ "<LEADER>sh", "<CMD>Telescope help_tags<CR>", desc = "search: help" },
					{ "<LEADER>sH", "<CMD>Telescope highlights<CR>", desc = "search: highlight groups" },
					{ "<LEADER>sk", "<CMD>Telescope keymaps<CR>", desc = "search: keymaps" },
					{ "<LEADER>sl", "<CMD>Telescope resume<CR>", desc = "search: resume last" },
					{ "<LEADER>sM", "<CMD>Telescope man_pages<CR>", desc = "search: man pages" },
					{ "<LEADER>sn", "<CMD>Telescope nerdy<CR>", desc = "search: nerdfont" },
					{
						"<LEADER>sp",
						"<CMD>lua require('telescope.builtin').colorscheme({enable_preview = true})<CR>",
						desc = "search: colorscheme with preview",
					},
					{ "<LEADER>sr", "<CMD>Telescope oldfiles<CR>", desc = "search: recent file" },
					{ "<LEADER>sR", "<CMD>Telescope registers<CR>", desc = "search: registers" },
					{ "<LEADER>st", "<CMD>Telescope live_grep<CR>", desc = "search: text" },
					{ "<LEADER>su", "<CMD>Telescope undo<CR>", desc = "search: undo" },
					-- smear cursor
					{ "<LEADER>S", "<CMD>SmearCursorToggle<CR>", desc = "smearcursor: toggle" },
					-- terminal
					{ "<LEADER>t", group = "terminal" },
					{
						"<LEADER>ts",
						"<CMD>ToggleTerm direction=horizontal<CR>",
						desc = "terminal: horizontal",
					},
					{
						"<LEADER>tv",
						"<CMD>ToggleTerm direction=vertical<CR>",
						desc = "terminal: vertical",
					},
					-- translate
					{ "<LEADER>T", "<CMD>Translate<CR>", desc = "translate current line" },
					-- zellij integration
					{ "<LEADER>z", group = "zellij" },
					{ "<LEADER>zs", "<CMD>ZellijSendBuffer<CR>", desc = "zellij: send buffer (delete)" },
					{ "<LEADER>zS", "<CMD>ZellijSendLine<CR>", desc = "zellij: send line (delete)" },
					{ "<LEADER>zk", "<CMD>ZellijSendBufferKeep<CR>", desc = "zellij: send buffer (keep)" },
					{ "<LEADER>zK", "<CMD>ZellijSendLineKeep<CR>", desc = "zellij: send line (keep)" },
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
					-- git
					{ "<LEADER>g", group = "git" },
					{ "<LEADER>gr", "<CMD>Gitsigns reset_hunk<CR>", desc = "git: reset hunk (visual)" },
					{ "<LEADER>gs", "<CMD>Gitsigns stage_hunk<CR>", desc = "git: stage hunk (visual)" },
					-- lsp
					{ "<LEADER>l", group = "lsp" },
					{ "<LEADER>la", "<CMD>lua vim.lsp.buf.code_action()<CR>", desc = "lsp: code action (visual)" },
					-- comment
					{
						"<LEADER>/",
						"<Plug>(comment_toggle_linewise_visual)",
						desc = "comment toggle linewise (visual)",
					},
				},
			})
		end,
	},
}
