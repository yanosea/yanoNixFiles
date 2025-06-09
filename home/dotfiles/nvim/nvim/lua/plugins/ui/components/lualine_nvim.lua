-- status line config
return {
	{
		"nvim-lualine/lualine.nvim",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"NStefan002/screenkey.nvim",
		},
		lazy = true,
		event = "VimEnter",
		config = function()
			local colors = require("utils.colors").colors
			local icons = require("utils.icons").icons
			-- define the conditions for when to show or hide certain components
			local conditions = {
				hide_in_width = function()
					return vim.fn.winwidth(0) > 80
				end,
			}
			-- define the utils functions
			local utils = {
				-- clean up the python virtual environment path
				env_cleanup = function(venv)
					if string.find(venv, "/") then
						local final_venv = venv
						for w in venv:gmatch("([^/]+)") do
							final_venv = w
						end
						return final_venv
					end
					return venv
				end,
				-- extract the command name from the raw command
				extract_command_name = function(raw_command)
					if raw_command == "" then
						return ""
					end
					local normalized_cmd = string.gsub(raw_command, "//", "/")
					local cmd_parts = {}
					for part in string.gmatch(normalized_cmd, "%S+") do
						table.insert(cmd_parts, part)
					end
					if #cmd_parts > 0 then
						local path = cmd_parts[1]
						return string.match(path, "([^/\\]+)$") or ""
					end
					return ""
				end,
				-- remove duplicates from a table
				deduplicate = function(tbl)
					local unique = {}
					for _, v in ipairs(tbl) do
						unique[v] = true
					end
					local result = {}
					for k, _ in pairs(unique) do
						table.insert(result, k)
					end
					return result
				end,
			}
			-- define git diff source function
			local function diff_source()
				local gitsigns = vim.b.gitsigns_status_dict
				if gitsigns then
					return {
						added = gitsigns.added,
						modified = gitsigns.changed,
						removed = gitsigns.removed,
					}
				end
			end
			-- define the function to get the scrollbar
			local function get_scrollbar()
				local current_line = vim.fn.line(".")
				local total_lines = vim.fn.line("$")
				local chars = {
					icons.scrollbars.Min,
					icons.scrollbars.Bar1,
					icons.scrollbars.Bar2,
					icons.scrollbars.Bar3,
					icons.scrollbars.Bar4,
					icons.scrollbars.Bar5,
					icons.scrollbars.Bar6,
					icons.scrollbars.Bar7,
					icons.scrollbars.Max,
				}
				local line_ratio = current_line / total_lines
				local index = math.ceil(line_ratio * #chars)
				return chars[index]
			end
			-- define the function to get lsp info
			local function get_lsp_info()
				local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
				-- if there are no clients, return "lsp inactive"
				if vim.fn.expand("%") == "" or #buf_clients == 0 then
					return "lsp inactive"
				end
				local buf_client_names = {}
				local copilot_active = false
				local efm_active = false
				local efm_tools = {}
				-- each client
				for _, client in pairs(buf_clients) do
					if client.name == "copilot" then
						copilot_active = true
						goto continue
					end
					-- efm client
					if client.name == "efm" then
						efm_active = true
						local ft = vim.bo.filetype
						if client.config and client.config.settings and client.config.settings.languages then
							local ft_tools = client.config.settings.languages[ft]
							if ft_tools then
								for _, tool in ipairs(ft_tools) do
									local raw_command = tool.prefix or tool.lintCommand or tool.formatCommand or ""
									local tool_name = utils.extract_command_name(raw_command)
									if tool_name ~= "" then
										table.insert(efm_tools, tool_name)
									end
								end
							end
						end
					end
					table.insert(buf_client_names, client.name)
					::continue::
				end
				-- process efm client names
				if efm_active then
					local client_names_new = {}
					for _, name in ipairs(buf_client_names) do
						if name == "efm" then
							if #efm_tools > 0 then
								local tool_list = utils.deduplicate(efm_tools)
								local tool_info = "efm(" .. table.concat(tool_list, ", ") .. ")"
								table.insert(client_names_new, tool_info)
							end
						else
							table.insert(client_names_new, name)
						end
					end
					buf_client_names = client_names_new
				end
				-- process client names
				local unique_client_names = table.concat(buf_client_names, ", ")
				local language_servers = string.format("[%s]", unique_client_names)
				-- update the color of the LualineCopilot highlight group
				if copilot_active then
					vim.api.nvim_set_hl(0, "LualineCopilot", { fg = colors.Green })
					language_servers = language_servers .. " %#LualineCopilot#" .. icons.git.Octoface .. " " .. "%*"
				elseif language_servers == "[]" then
					return "#{LualineCopilot}" .. icons.git.Octoface .. " " .. "%*"
				end
				-- if the language servers are empty, return "lsp inactive"
				if language_servers == "[]" then
					return "lsp inactive"
				end
				return language_servers
			end
			-- define the function to get the python environment
			local function get_python_env()
				if vim.bo.filetype == "python" then
					local venv = vim.env.CONDA_DEFAULT_ENV or vim.env.VIRTUAL_ENV
					if venv then
						local devicons = require("nvim-web-devicons")
						local py_icon, _ = devicons.get_icon(".py")
						return string.format(" " .. py_icon .. " (%s)", utils.env_cleanup(venv))
					end
				end
				return ""
			end
			-- define components
			local components = {
				mode = {
					function()
						return " " .. icons.ui.Target .. " "
					end,
					padding = { left = 0, right = 0 },
					color = {},
					cond = nil,
				},
				branch = {
					"b:gitsigns_head",
					icon = icons.git.Branch,
					color = { gui = "bold" },
				},
				filename = {
					"filename",
					color = {},
					cond = nil,
				},
				diff = {
					"diff",
					source = diff_source,
					symbols = {
						added = icons.git.LineAdded .. " ",
						modified = icons.git.LineModified .. " ",
						removed = icons.git.LineRemoved .. " ",
					},
					padding = { left = 2, right = 1 },
					diff_color = {
						added = { fg = colors.Green },
						modified = { fg = colors.Yellow },
						removed = { fg = colors.Red },
					},
					cond = nil,
				},
				python_env = {
					get_python_env,
					color = { fg = colors.Green },
					cond = conditions.hide_in_width,
				},
				diagnostics = {
					"diagnostics",
					sources = { "nvim_diagnostic" },
					symbols = {
						error = icons.diagnostics.BoldError .. " ",
						warn = icons.diagnostics.BoldWarning .. " ",
						info = icons.diagnostics.BoldInformation .. " ",
						hint = icons.diagnostics.BoldHint .. " ",
					},
				},
				treesitter = {
					function()
						return icons.ui.Tree .. " "
					end,
					color = function()
						local buf = vim.api.nvim_get_current_buf()
						local ts = vim.treesitter.highlighter.active[buf]
						return { fg = ts and not vim.tbl_isempty(ts) and colors.Green or colors.Red }
					end,
					cond = conditions.hide_in_width,
				},
				screenkey = {
					function()
						return require("screenkey").get_keys()
					end,
				},
				lsp = {
					get_lsp_info,
					color = { gui = "bold" },
					cond = conditions.hide_in_width,
				},
				location = { "location" },
				progress = {
					"progress",
					fmt = function()
						return "%P/%L"
					end,
					color = {},
				},
				spaces = {
					function()
						local shiftwidth = vim.api.nvim_get_option_value("shiftwidth", { buf = 0 })
						return icons.ui.Tab .. " " .. shiftwidth
					end,
					padding = 1,
				},
				encoding = {
					"o:encoding",
					fmt = string.upper,
					color = {},
					cond = conditions.hide_in_width,
				},
				filetype = {
					"filetype",
					cond = nil,
					padding = { left = 1, right = 1 },
				},
				scrollbar = {
					get_scrollbar,
					padding = { left = 0, right = 0 },
					color = { fg = colors.Blue, bg = colors.Green },
					cond = nil,
				},
			}
			-- if headless mode is detected, skip lualine setup
			if #vim.api.nvim_list_uis() == 0 then
				print("headless mode detected, skipping lualine setup")
				return
			end
			-- screenkey.nvim config
			require("screenkey").setup({
				compress_after = 3,
				clear_after = 1,
				emit_events = true,
				disable = {
					filetypes = {
						"TelescopePrompt",
						"toggleterm",
					},
					buftypes = {},
				},
				show_leader = true,
				group_mappings = true,
				filter = function(keys)
					-- ifnore in insert mode
					if vim.fn.mode() == "i" then
						return {}
					end
					return keys
				end,
				colorize = function(keys)
					return keys
				end,
				separator = " ",
				keys = {
					["<TAB>"] = icons.keys.Tab,
					["<CR>"] = icons.keys.CarriageReturn,
					["<ESC>"] = icons.keys.Escape,
					["<SPACE>"] = icons.keys.Space,
					["<BS>"] = icons.keys.BackSpace,
					["<DEL>"] = icons.keys.Delete,
					["<LEFT>"] = icons.keys.Left,
					["<RIGHT>"] = icons.keys.Right,
					["<UP>"] = icons.keys.Up,
					["<DOWN>"] = icons.keys.Down,
					["<HOME>"] = icons.keys.Home,
					["<END>"] = icons.keys.End,
					["<PAGEUP>"] = icons.keys.PageUp,
					["<PAGEDOWN>"] = icons.keys.PageDown,
					["<INSERT>"] = icons.keys.Insert,
					["<F1>"] = icons.keys.F1,
					["<F2>"] = icons.keys.F2,
					["<F3>"] = icons.keys.F3,
					["<F4>"] = icons.keys.F4,
					["<F5>"] = icons.keys.F5,
					["<F6>"] = icons.keys.F6,
					["<F7>"] = icons.keys.F7,
					["<F8>"] = icons.keys.F8,
					["<F9>"] = icons.keys.F9,
					["<F10>"] = icons.keys.F10,
					["<F11>"] = icons.keys.F11,
					["<F12>"] = icons.keys.F12,
					["CTRL"] = icons.keys.Ctrl,
					["ALT"] = icons.keys.Alt,
					["SUPER"] = icons.keys.Super,
					["<leader>"] = icons.keys.Leader,
				},
			})
			-- toggle screenkey statusline component first
			require("screenkey").toggle_statusline_component()
			-- lualine.nvim config
			require("lualine").setup({
				options = {
					theme = vim.g.colors_name or "auto",
					globalstatus = true,
					icons_enabled = true,
					component_separators = {
						left = icons.ui.DividerRight,
						right = icons.ui.DividerLeft,
					},
					section_separators = {
						left = icons.ui.BoldDividerRight,
						right = icons.ui.BoldDividerLeft,
					},
					disabled_filetypes = { "alpha" },
				},
				sections = {
					lualine_a = { components.mode },
					lualine_b = {
						components.branch,
					},
					lualine_c = {
						components.filename,
						components.encoding,
						components.diff,
						components.python_env,
					},
					lualine_x = {
						components.screenkey,
						components.diagnostics,
						components.lsp,
						components.spaces,
						components.filetype,
						components.treesitter,
					},
					lualine_y = { components.location },
					lualine_z = { components.progress, components.scrollbar },
				},
				inactive_sections = {
					lualine_a = { components.mode },
					lualine_b = {
						components.branch,
					},
					lualine_c = {
						components.filename,
						components.encoding,
						components.diff,
						components.python_env,
					},
					lualine_x = {
						components.screenkey,
						components.diagnostics,
						components.lsp,
						components.spaces,
						components.filetype,
						components.treesitter,
					},
					lualine_y = { components.location },
					lualine_z = { components.progress, components.scrollbar },
				},
				tabline = {},
				extensions = {},
			})
		end,
	},
}
