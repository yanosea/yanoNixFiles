-- navigations in winbar
return {
	{
		"SmiteshP/nvim-navic",
		dependencies = {
			"nvim-web-devicons",
		},
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local navic = require("nvim-navic")
			local icons = require("utils.icons").icons
			local colors = require("utils.colors").colors
			-- nvim-navic config
			navic.setup({
				icons = {
					Array = icons.kind.Array,
					Boolean = icons.kind.Boolean,
					Class = icons.kind.Class,
					Color = icons.kind.Color,
					Constant = icons.kind.Constant,
					Constructor = icons.kind.Constructor,
					Enum = icons.kind.Enum,
					EnumMember = icons.kind.EnumMember,
					Event = icons.kind.Event,
					Field = icons.kind.Field,
					File = icons.kind.File,
					Folder = icons.kind.Folder,
					Function = icons.kind.Function,
					Interface = icons.kind.Interface,
					Key = icons.kind.Key,
					Keyword = icons.kind.Keyword,
					Method = icons.kind.Method,
					Module = icons.kind.Module,
					Namespace = icons.kind.Namespace,
					Null = icons.kind.Null,
					Number = icons.kind.Number,
					Object = icons.kind.Object,
					Operator = icons.kind.Operator,
					Package = icons.kind.Package,
					Property = icons.kind.Property,
					Reference = icons.kind.Reference,
					Snippet = icons.kind.Snippet,
					String = icons.kind.String,
					Struct = icons.kind.Struct,
					TypeParameter = icons.kind.TypeParameter,
					Unit = icons.kind.Unit,
					Value = icons.kind.Value,
					Variable = icons.kind.Variable,
				},
				lsp = {
					auto_attach = true,
					preference = nil,
				},
				highlight = true,
				separator = " " .. icons.ui.LineRightArrow .. " ",
				depth_limit = 0,
				depth_limit_indicator = "..",
				safe_output = true,
				lazy_update_context = false,
				click = false,
				format_text = function(text)
					return text
				end,
			})
			-- define get filename function
			local function get_filename()
				local filename = vim.fn.expand("%:t")
				local extension = vim.fn.expand("%:e")
				-- get the file name and extension
				if filename ~= "" then
					local file_icon, hl_group
					local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
					if devicons_ok then
						file_icon, hl_group = devicons.get_icon(filename, extension, { default = true })
					else
						file_icon = ""
						hl_group = "Normal"
					end
					if file_icon == nil then
						file_icon = ""
					end
					if file_icon == "" and icons and icons.kind and icons.kind.File then
						file_icon = icons.kind.File
					end
					-- check if the file is a dapui file
					local buf_ft = vim.bo.filetype
					if buf_ft == "dapui_breakpoints" then
						file_icon = icons.ui.BreakPoint
					elseif buf_ft == "dapui_stacks" then
						file_icon = icons.ui.Stacks
					elseif buf_ft == "dapui_scopes" then
						file_icon = icons.ui.Scopes
					elseif buf_ft == "dapui_watches" then
						file_icon = icons.ui.Watches
					elseif buf_ft == "dapui_console" then
						file_icon = icons.ui.DebugConsole
					elseif buf_ft == "dap-repl" then
						file_icon = icons.ui.CommandLineInput
					end
					if file_icon == nil then
						file_icon = ""
					end
					if hl_group == nil then
						hl_group = "Normal"
					end
					vim.api.nvim_set_hl(0, "Winbar", { fg = colors.Fg })
					return " " .. "%#" .. hl_group .. "#" .. file_icon .. "%*" .. " " .. "%#Winbar#" .. filename .. "%*"
				end
				return ""
			end
			-- define get excluded filetypes function
			function navic.get_excluded_filetypes()
				return {
					"help",
					"startify",
					"dashboard",
					"lazy",
					"neo-tree",
					"neogitstatus",
					"NvimTree",
					"Trouble",
					"alpha",
					"lir",
					"Outline",
					"spectre_panel",
					"TelescopePrompt",
					"toggleterm",
					"DressingSelect",
					"Jaq",
					"harpoon",
					"dap-repl",
					"dap-terminal",
					"dapui_console",
					"dapui_hover",
					"lab",
					"notify",
					"noice",
					"neotest-summary",
					"",
				}
			end
			-- overwrite navic.get_winbar function
			function navic.get_winbar()
				local buf_ft = vim.bo.filetype
				for _, ft in ipairs(navic.get_excluded_filetypes()) do
					if buf_ft == ft then
						return ""
					end
				end
				local filename = get_filename()
				local location = navic.get_location()
				if location and location ~= "" then
					return filename .. " " .. icons.ui.Separator .. "  " .. location
				else
					return filename
				end
			end
			-- create a new autocmd
			vim.api.nvim_create_autocmd({ "BufWinEnter", "BufFilePost", "FileType" }, {
				callback = function()
					if vim.tbl_contains(navic.get_excluded_filetypes(), vim.bo.filetype) then
						vim.opt_local.winbar = nil
					else
						vim.opt_local.winbar = "%{%v:lua.require'nvim-navic'.get_winbar()%}"
					end
				end,
			})
		end,
	},
}
