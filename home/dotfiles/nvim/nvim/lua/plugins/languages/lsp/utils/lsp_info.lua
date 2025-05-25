-- overwrite LspInfo command
local M = {}
function M.setup()
	vim.api.nvim_create_user_command("LspInfo", function()
		local clients = vim.lsp.get_clients()
		local bufnr = vim.api.nvim_get_current_buf()
		local ft = vim.bo[bufnr].filetype
		local log_path = vim.lsp.get_log_path()
		local header = {
			" Press q or <Esc> to close this window. Press <Tab> to view server doc.",
			"",
			string.format(" Language client log: %s", log_path),
			string.format(" Detected filetype:   %s", ft),
			"",
		}
		-- sort clients into attached and unattached
		local attached_clients = {}
		local unattached_clients = {}
		for _, client in ipairs(clients) do
			if vim.lsp.buf_is_attached(bufnr, client.id) then
				table.insert(attached_clients, client)
			else
				table.insert(unattached_clients, client)
			end
		end
		-- helper functions
		-- resolve the full path of a command
		local function resolve_full_path(cmd)
			if not cmd or cmd == "" or cmd:sub(1, 1) == "/" then
				return cmd
			end
			local handle = io.popen("which " .. cmd .. " 2>/dev/null")
			if handle then
				local result = handle:read("*a"):gsub("%s+$", "")
				handle:close()
				if result ~= "" then
					return result
				end
			end
			local paths = vim.split(vim.env.PATH, ":")
			for _, path in ipairs(paths) do
				local full_path = path .. "/" .. cmd
				if vim.fn.executable(full_path) == 1 then
					return full_path
				end
			end
			return cmd
		end
		-- get the command used to start the client
		local function get_client_cmd(client)
			local cmd = "Not available"
			if client.config and client.config.cmd then
				if type(client.config.cmd) == "table" and #client.config.cmd > 0 then
					local cmd_args = {}
					local base_cmd = client.config.cmd[1]
					local full_path_cmd = resolve_full_path(base_cmd)
					table.insert(cmd_args, full_path_cmd)
					for i = 2, #client.config.cmd do
						table.insert(cmd_args, client.config.cmd[i])
					end
					cmd = table.concat(cmd_args, " ")
				elseif type(client.config.cmd) == "function" then
					cmd = "<function>"
				else
					cmd = tostring(client.config.cmd)
				end
			end
			return cmd
		end
		-- get the list of buffers associated with a client
		local function get_buffer_list(client_id)
			local buf_list = "["
			for i, buf_id in ipairs(vim.lsp.get_buffers_by_client_id(client_id) or {}) do
				if i > 1 then
					buf_list = buf_list .. ", "
				end
				buf_list = buf_list .. tostring(buf_id)
			end
			buf_list = buf_list .. "]"
			return buf_list
		end
		-- get the root directory of a client
		local function get_root_dir(client)
			local root_dir = "Running in single file mode."
			if client.config and client.config.root_dir then
				if type(client.config.root_dir) == "function" then
					local status, dir = pcall(client.config.root_dir)
					if status and dir and dir ~= "" then
						root_dir = dir
					end
				elseif type(client.config.root_dir) == "string" and client.config.root_dir ~= "" then
					root_dir = client.config.root_dir
				end
			end
			return root_dir
		end
		-- get the filetypes associated with a client
		local function get_filetypes(client)
			local filetypes = ""
			if client.config and client.config.filetypes then
				if #client.config.filetypes > 0 then
					filetypes = table.concat(client.config.filetypes, ", ")
				else
					filetypes = "*"
				end
			end
			return filetypes
		end
		-- get the autostart status of a client
		local function get_autostart(client)
			local autostart = "false"
			if client.config and client.config.autostart ~= nil then
				autostart = client.config.autostart and "true" or "false"
			end
			return autostart
		end
		-- display unique tools
		local function display_unique_tools(tools_list, label)
			if #tools_list > 0 then
				local unique_tools = {}
				for _, v in ipairs(tools_list) do
					unique_tools[v] = true
				end
				local tool_list = {}
				for tool, _ in pairs(unique_tools) do
					table.insert(tool_list, tool)
				end
				table.sort(tool_list)
				return string.format(" \t%-16s %s", label .. ":", table.concat(tool_list, ", "))
			end
			return nil
		end
		-- get tools from config section
		local function get_tools_from_config(config_section)
			if not config_section then
				return {}
			end
			local tools = {}
			for tool_name, _ in pairs(config_section) do
				table.insert(tools, tool_name)
			end
			return tools
		end
		-- build client information sections
		local function build_client_info(client, is_attached)
			local info = {}
			local buf_list = get_buffer_list(client.id)
			local prefix = is_attached and " Client: " or " Client: "
			table.insert(info, string.format("%s%s (id: %d, bufnr: %s)", prefix, client.name, client.id, buf_list))
			table.insert(info, string.format(" \tfiletypes:       %s", get_filetypes(client)))
			table.insert(info, string.format(" \tautostart:       %s", get_autostart(client)))
			table.insert(info, string.format(" \troot directory:  %s", get_root_dir(client)))
			table.insert(info, string.format(" \tcmd:             %s", get_client_cmd(client)))
			-- special handling for efm
			if client.name == "efm" then
				-- find efm config file
				local config_paths = {
					vim.fn.expand("~/.config/efm-langserver/config.yaml"),
					vim.fn.expand("~/.efm-langserver.yaml"),
				}
				local config_path = "Config not found"
				for _, path in ipairs(config_paths) do
					if vim.fn.filereadable(path) == 1 then
						config_path = path
						break
					end
				end
				table.insert(info, string.format(" \tefm config:      %s", config_path))
				-- handle efm language tools
				if client.config and client.config.settings and client.config.settings.languages then
					local buf_ft = vim.bo[bufnr].filetype
					local formatters = {}
					local linters = {}
					local action_tools = {}
					if client.config.settings.languages[buf_ft] then
						local ft_tools = client.config.settings.languages[buf_ft]
						if ft_tools then
							for _, tool in ipairs(ft_tools) do
								if tool and type(tool) == "table" then
									local raw_command = tool.prefix or tool.lintCommand or tool.formatCommand or ""
									local tool_name = ""
									if raw_command ~= "" then
										local normalized_cmd = string.gsub(raw_command, "//", "/")
										local cmd_parts = {}
										for part in string.gmatch(normalized_cmd, "%S+") do
											table.insert(cmd_parts, part)
										end
										if #cmd_parts > 0 then
											local path = cmd_parts[1]
											tool_name = string.match(path, "([^/\\]+)$") or ""
										end
									end
									if tool_name ~= "" then
										if tool.formatCommand then
											table.insert(formatters, tool_name)
										elseif tool.lintCommand then
											table.insert(linters, tool_name)
										elseif tool.codeActionCommand then
											table.insert(action_tools, tool_name)
										end
									end
								end
							end
						end
					end
					local formatter_line = display_unique_tools(formatters, "formatters")
					if formatter_line then
						table.insert(info, formatter_line)
					end
					local linter_line = display_unique_tools(linters, "linters")
					if linter_line then
						table.insert(info, linter_line)
					end
					local action_line = display_unique_tools(action_tools, "action tools")
					if action_line then
						table.insert(info, action_line)
					end
				end
				-- handle efm init options
				local init_options = client.config and client.config.init_options or {}
				local sections = {
					{ key = "codeAction", label = "code actions" },
					{ key = "hover", label = "hover tools" },
					{ key = "documentSymbol", label = "symbol tools" },
				}
				for _, section in ipairs(sections) do
					local tools = init_options[section.key] and get_tools_from_config(init_options[section.key]) or {}
					if #tools > 0 then
						table.insert(
							info,
							string.format(" \t%-16s %s", section.label .. ":", table.concat(tools, ", "))
						)
					end
				end
				-- show capabilities
				local capabilities = {}
				if client.server_capabilities.documentFormattingProvider then
					table.insert(capabilities, "formatting")
				end
				if client.server_capabilities.codeActionProvider then
					table.insert(capabilities, "code actions")
				end
				if client.server_capabilities.hoverProvider then
					table.insert(capabilities, "hover")
				end
				if client.server_capabilities.documentSymbolProvider then
					table.insert(capabilities, "document symbols")
				end
				if #capabilities > 0 then
					table.insert(info, string.format(" \tcapabilities:    %s", table.concat(capabilities, ", ")))
				end
			end
			table.insert(info, "")
			return info
		end
		-- create sections
		local client_info = {}
		if #attached_clients > 0 then
			table.insert(client_info, string.format(" %d client(s) attached to this buffer: ", #attached_clients))
			table.insert(client_info, "")
			for _, client in ipairs(attached_clients) do
				local client_details = build_client_info(client, true)
				for _, line in ipairs(client_details) do
					table.insert(client_info, line)
				end
			end
		else
			table.insert(client_info, " No clients attached to this buffer.")
			table.insert(client_info, "")
		end
		local unattached_info = {}
		if #unattached_clients > 0 then
			table.insert(
				unattached_info,
				string.format(" %d active client(s) not attached to this buffer: ", #unattached_clients)
			)
			table.insert(unattached_info, "")
			for _, client in ipairs(unattached_clients) do
				local client_details = build_client_info(client, false)
				for _, line in ipairs(client_details) do
					table.insert(unattached_info, line)
				end
			end
		end
		-- find other potential clients for this filetype
		local other_clients_info = {}
		local configured_servers = {}
		local lspconfig = require("lspconfig")
		local other_clients = {}
		for server_name, server_obj in pairs(lspconfig) do
			if type(server_obj) == "table" and server_obj.document_config then
				local server_filetypes = server_obj.document_config.default_config.filetypes
				if
					server_filetypes and vim.tbl_contains(server_filetypes, ft)
					or (server_filetypes and #server_filetypes == 0)
					or server_name == "efm"
				then
					table.insert(configured_servers, server_name)
					-- check if this server is already active
					local is_attached = false
					for _, client in ipairs(clients) do
						if client.name == server_name then
							is_attached = true
							break
						end
					end
					if not is_attached then
						table.insert(other_clients, { name = server_name, config = server_obj })
					end
				end
			end
		end
		if #other_clients > 0 then
			table.insert(other_clients_info, string.format(" Other clients that match the filetype: %s", ft))
			table.insert(other_clients_info, "")
			for _, server in ipairs(other_clients) do
				local server_default_config = server.config.document_config.default_config
				local cmd = "Not specified"
				if server_default_config.cmd then
					if type(server_default_config.cmd) == "table" and #server_default_config.cmd > 0 then
						local cmd_args = {}
						local base_cmd = server_default_config.cmd[1]
						local full_path_cmd = resolve_full_path(base_cmd)
						table.insert(cmd_args, full_path_cmd)
						for i = 2, #server_default_config.cmd do
							table.insert(cmd_args, server_default_config.cmd[i])
						end
						cmd = table.concat(cmd_args, " ")
					elseif type(server_default_config.cmd) == "function" then
						cmd = "<function>"
					else
						cmd = tostring(server_default_config.cmd)
					end
				end
				local filetypes = "*"
				if server_default_config.filetypes and #server_default_config.filetypes > 0 then
					filetypes = table.concat(server_default_config.filetypes, ", ")
				end
				local root_dir = "Not found."
				if server_default_config.root_dir then
					root_dir = "<function>"
				end
				local cmd_executable = "false"
				if type(server_default_config.cmd) == "table" and server_default_config.cmd[1] then
					cmd_executable = vim.fn.executable(server_default_config.cmd[1]) == 1 and "true" or "false"
				end
				local autostart = "true"
				if server_default_config.autostart ~= nil then
					autostart = server_default_config.autostart and "true" or "false"
				end
				table.insert(other_clients_info, string.format(" Config: %s", server.name))
				table.insert(other_clients_info, string.format(" \tfiletypes:         %s", filetypes))
				table.insert(other_clients_info, string.format(" \troot directory:    %s", root_dir))
				table.insert(other_clients_info, string.format(" \tcmd:               %s", cmd))
				table.insert(other_clients_info, string.format(" \tcmd is executable: %s", cmd_executable))
				table.insert(other_clients_info, string.format(" \tautostart:         %s", autostart))
				table.insert(other_clients_info, " \tcustom handlers:   ")
				table.insert(other_clients_info, "")
			end
		end
		local servers_list = {}
		if #configured_servers > 0 then
			table.insert(
				servers_list,
				string.format(" Configured servers list: %s", table.concat(configured_servers, ", "))
			)
			table.insert(servers_list, "")
		end
		-- combine all content sections
		local content = {}
		for _, section in ipairs({
			header,
			client_info,
			unattached_info,
			other_clients_info,
			servers_list,
		}) do
			for _, line in ipairs(section) do
				table.insert(content, line)
			end
		end
		-- calculate window dimensions
		local max_line_length = 0
		for _, line in ipairs(content) do
			max_line_length = math.max(max_line_length, #line)
		end
		local width = math.min(vim.o.columns - 4, math.max(80, max_line_length + 4))
		local height = math.min(#content + 2, vim.o.lines - 4)
		-- create buffer and window
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
		vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
		vim.api.nvim_set_option_value("filetype", "lspinfo", { buf = buf })
		vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
		local win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = math.floor((vim.o.lines - height) / 2),
			col = math.floor((vim.o.columns - width) / 2),
			style = "minimal",
			border = "single",
		})
		vim.api.nvim_set_option_value("wrap", true, { win = win })
		vim.api.nvim_set_option_value("cursorline", true, { win = win })
		-- set up highlighting
		local colors = require("utils.colors").colors
		vim.cmd(
			string.format(
				[[
      highlight LspInfoBorder guifg=%s
      highlight LspInfoTitle guifg=%s
      highlight LspInfoHeader guifg=%s gui=bold
      highlight LspInfoFiletype guifg=%s gui=bold
      highlight LspInfoList guifg=%s
      highlight LspInfoClient guifg=%s gui=bold
      highlight LspInfoConfig guifg=%s gui=bold
      highlight LspInfoServerName guifg=%s
      highlight LspInfoTrue guifg=%s
      highlight LspInfoFalse guifg=%s
    ]],
				colors.Blue,
				colors.Yellow,
				colors.Blue,
				colors.Green,
				colors.Fg,
				colors.Blue,
				colors.Purple,
				colors.Aqua,
				colors.Green,
				colors.Red
			)
		)
		vim.api.nvim_set_option_value("winhl", "Normal:Normal,FloatBorder:LspInfoBorder", { win = win })
		-- set up text highlighting patterns
		local function add_match(group, pattern)
			pcall(vim.fn.matchadd, group, pattern)
		end
		add_match("LspInfoHeader", "^ Language client log:")
		add_match("LspInfoHeader", "^ Detected filetype:")
		add_match("LspInfoFiletype", " " .. ft .. "$")
		add_match("LspInfoHeader", "^ %d+ client%(s%) attached to this buffer:")
		add_match("LspInfoHeader", "^ %d+ active client%(s%) not attached to this buffer:")
		add_match("LspInfoHeader", "^ Other clients that match the filetype:")
		add_match("LspInfoHeader", "^ Configured servers list:")
		add_match("LspInfoClient", "^ Client: [^ ]\\+")
		add_match("LspInfoConfig", "^ Config: [^ ]\\+")
		add_match("LspInfoList", "^ \\+\\w\\+:\\s\\+")
		add_match("LspInfoTrue", "true")
		add_match("LspInfoFalse", "false")
		add_match("Comment", "^\\s*Press q or")
		-- set up key mappings
		vim.api.nvim_buf_set_keymap(
			buf,
			"n",
			"q",
			":close<CR>",
			{ desc = "close lsp info", silent = true, noremap = true }
		)
		vim.api.nvim_buf_set_keymap(
			buf,
			"n",
			"<Esc>",
			":close<CR>",
			{ desc = "close lsp info", silent = true, noremap = true }
		)
		vim.api.nvim_buf_set_keymap(buf, "n", "<Tab>", "", {
			desc = "open server documentation",
			noremap = true,
			callback = function()
				local line = vim.api.nvim_get_current_line()
				local client_pattern = "^ Client: ([^ ]+)"
				local config_pattern = "^ Config: ([^ ]+)"
				local server_name = line:match(client_pattern) or line:match(config_pattern)
				if server_name then
					local doc_url = "https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#"
						.. server_name
					vim.fn.system({ "xdg-open", doc_url })
				end
			end,
		})
	end, {})
end
return M
