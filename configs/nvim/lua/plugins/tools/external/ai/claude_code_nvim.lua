-- claude code plugin
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>al)
return {
	{
		"greggh/claude-code.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		lazy = true,
		cmd = {
			"ClaudeCode",
			"ClaudeCodeContinue",
			"ClaudeCodeResume",
			"ClaudeCodeVerbose",
			"ClaudeCodeSendBuffer",
			"ClaudeCodeSendLine",
		},
		config = function()
			-- claude-code.nvim config
			require("claude-code").setup({
				-- Terminal window settings
				window = {
					split_ratio = 0.3, -- Percentage of screen for the terminal window (height for horizontal, width for vertical splits)
					position = "rightbelow vsplit", -- Position of the window: "botright", "topleft", "vertical", "rightbelow vsplit", etc.
					enter_insert = true, -- Whether to enter insert mode when opening Claude Code
					hide_numbers = true, -- Hide line numbers in the terminal window
					hide_signcolumn = true, -- Hide the sign column in the terminal window
				},
				-- File refresh settings
				refresh = {
					enable = true, -- Enable file change detection
					updatetime = 100, -- updatetime when Claude Code is active (milliseconds)
					timer_interval = 1000, -- How often to check for file changes (milliseconds)
					show_notifications = true, -- Show notification when files are reloaded
				},
				-- Git project settings
				git = {
					use_git_root = true, -- Set CWD to git root when opening Claude Code (if in git project)
				},
				-- Shell-specific settings
				shell = {
					separator = "&&", -- Command separator used in shell commands
					pushd_cmd = "pushd", -- Command to push directory onto stack (e.g., 'pushd' for bash/zsh, 'enter' for nushell)
					popd_cmd = "popd", -- Command to pop directory from stack (e.g., 'popd' for bash/zsh, 'exit' for nushell)
				},
				-- Command settings
				command = "claude", -- Command used to launch Claude Code
				-- Command variants
				command_variants = {
					-- Conversation management
					continue = "--continue", -- Resume the most recent conversation
					resume = "--resume", -- Display an interactive conversation picker
					-- Output options
					verbose = "--verbose", -- Enable verbose logging with full turn-by-turn output
				},
				-- Keymaps
				keymaps = {
					toggle = {
						normal = false, -- Normal mode keymap for toggling Claude Code, false to disable
						terminal = false, -- Terminal mode keymap for toggling Claude Code, false to disable
						variants = {
							continue = false, -- Normal mode keymap for Claude Code with continue flag
							verbose = false, -- Normal mode keymap for Claude Code with verbose flag
						},
					},
					window_navigation = true, -- Enable window navigation keymaps (<C-h/j/k/l>)
					scrolling = true, -- Enable scrolling keymaps (<C-f/b>) for page up/down
				},
			})
			-- Zellij integration functions
			-- Session cache for pane ID (cleared when neovim restarts)
			local cached_pane_id = nil
			-- Function to find the Claude pane in Zellij
			local function find_claude_pane()
				-- Return cached pane ID if available
				if cached_pane_id then
					return cached_pane_id
				end
				-- First, try list-clients to find active Claude process
				local handle = io.popen("zellij action list-clients")
				if handle then
					local result = handle:read("*a")
					handle:close()
					for line in result:gmatch("[^\r\n]+") do
						if not line:match("CLIENT_ID") then
							if line:match("claude") then
								local _, pane_id, command = line:match("^%s*(%S+)%s+(%S+)%s+(.-)%s*$")
								if pane_id and command and command:match("claude") then
									cached_pane_id = pane_id
									return pane_id
								end
							end
						end
					end
				end
				-- If list-clients doesn't show claude, ask user for pane id
				local ps_handle = io.popen("ps aux | grep 'claude' | grep -v grep | head -1")
				if ps_handle then
					local ps_result = ps_handle:read("*a")
					ps_handle:close()
					if ps_result and ps_result ~= "" then
						local pane_num = vim.fn.input("Enter Claude pane number (e.g. 1 for terminal_1): ")
						if pane_num and pane_num ~= "" then
							-- Convert number to terminal_X format
							local pane_id = "terminal_" .. pane_num
							-- Cache for this session
							cached_pane_id = pane_id
							return pane_id
						end
					end
				end
				vim.notify("No Claude pane found", vim.log.levels.WARN)
				return nil
			end
			-- function to send text to Claude pane in Zellij
			local function send_to_zellij_pane(text)
				-- Check if we're in a zellij session
				if not os.getenv("ZELLIJ") then
					vim.notify("Not running in a Zellij session", vim.log.levels.ERROR)
					return
				end
				-- Find Claude pane
				local claude_pane = find_claude_pane()
				if not claude_pane then
					vim.notify("Could not find Claude pane. Make sure Claude is running.", vim.log.levels.ERROR)
					return
				end
				-- Escape text only for single quotes (minimal escaping)
				local escaped_text = text:gsub("'", "'\"'\"'")
				-- Send text to Claude pane with Enter key
				-- IMPORTANT : Claude pane must be positioned above the neovim pane in Zellij
				local script = string.format(
					[[
					zellij action move-focus up
					sleep 0.1
					zellij action write-chars '%s'
					sleep 0.1
					zellij action write-chars $'\r'
					sleep 0.1
					zellij action move-focus down
				]],
					escaped_text
				)
				local success = os.execute(script)
				if success then
					vim.notify("Text sent to Claude pane " .. claude_pane, vim.log.levels.INFO)
				else
					vim.notify("Failed to send text to Claude pane", vim.log.levels.ERROR)
				end
			end
			-- Send current line to Claude pane
			vim.api.nvim_create_user_command("ClaudeCodeSendLine", function()
				local line = vim.fn.getline(".")
				send_to_zellij_pane(line .. "\n")
			end, { desc = "Send current line to Claude pane" })
			-- Send buffer content to Claude pane (with size limit)
			vim.api.nvim_create_user_command("ClaudeCodeSendBuffer", function()
				local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
				local text = table.concat(lines, "\n")
				-- Check buffer size (limit to reasonable size)
				if #text > 5000 then
					vim.notify("Buffer too large (" .. #text .. " chars). Max 5000 chars.", vim.log.levels.WARN)
					return
				end
				send_to_zellij_pane(text .. "\n")
			end, { desc = "Send buffer content to Claude pane" })
		end,
	},
}
