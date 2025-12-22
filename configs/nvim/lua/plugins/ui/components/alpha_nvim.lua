-- dashboard config
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>;)
return {
	{
		"goolord/alpha-nvim",
		lazy = true,
		event = "VimEnter",
		config = function()
			local dashboard = require("alpha.themes.dashboard")
			-- header
			local header_large = {
				"            ⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀            ",
				"            ⠀⠀⠀⣰⣿⣿⣿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠿⠛⠛⠛⠻⢿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀            ",
				"            ⠀⠀⢠⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀            ",
				"            ⠀⢀⣾⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣹⣿⡇⠀⠀⠀⠀⠀⠀⠀            ",
				"            ⠀⣼⣿⣿⣿⣿⣿⣤⣤⣤⣤⣤⣴⣶⠆⠀⠀⠀⠀⠀⠀⢀⣴⣶⣶⡶⠂⠀⠀⠀⠀⠀⠀⣼⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀            ",
				"            ⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⢀⣾⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀            ",
				"            ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⣴⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⢠⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀            ",
				"            ⢻⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣶⣶⣾⣿⣶⡄⠀⠀⠀⠀⠀            ",
				"            ⢸⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠛⠛⠛⠛⠁⠀⠀⠀⠀⠀⠀⣼⡿⠋⠉⠉⠉⠁⠀⠈⣿⣷⠀⠀⠀⠀⠀            ",
				"            ⠀⣿⣿⣿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⡟⠁⠀⠀⠀⠀⠀⠀⠀⢹⣿⡆⠀⠀⠀⠀            ",
				"            ⠀⠹⠟⠛⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⣷⠀⠀⠀⠀            ",
				"            ⠀⠀⠀⣼⣿⣿⣿⣿⣿⣇⣀⣠⣤⣤⣤⣤⡄⠀⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⣰⣿⡟⠀⠀⠀⠀            ",
				"            ⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⣰⣿⡟⠀⠀⠀⠀⠀            ",
				"            ⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠋⠀⠀⠀⠀⠀⠀⢀⣾⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀⣰⣿⣿⣁⣀⡀⠀⠀⠀            ",
				"            ⠀⠀⠈⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⣠⣿⣿⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⣧⠀⠀            ",
				"            ⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⠟⠀⠀⠀⠀⠀⠀⠀⠰⠿⠿⠿⠿⠟⠛⠀⠀⠀⠀⠀⠀⠀⠀⠉⠁⠀⠀⠀⠀⣿⣿⡆⠀            ",
				"            ⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣷⠀            ",
				"            ⠀⠀⠀⠈⠛⠋⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣿⣿⡆            ",
				"            ⠀⠀⠀⠀⠀⣼⣿⣿⣿⣿⣿⣷⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⣠⣤⣤⣤⣤⣤⣶⣶⣶⣶⣶⣶⣿⣿⣿⣿⣿⣿⡿⠃            ",
				"            ⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀            ",
				"            ⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠀            ",
				"            ⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀            ",
				"            ⠀⠀⠀⠀⠀⢹⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠿⠿⠟⠛⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀            ",
				"            ⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⠿⠿⠿⠟⠛⠛⠛⠛⠛⠉⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀            ",
				"                                                                    ",
			}
			local header_small = {
				"███╗   ██╗ ██████╗         ███████╗███████╗ █████╗         ",
				"████╗  ██║██╔═══██╗        ██╔════╝██╔════╝██╔══██╗        ",
				"██╔██╗ ██║██║   ██║        ███████╗█████╗  ███████║        ",
				"██║╚██╗██║██║   ██║        ╚════██║██╔══╝  ██╔══██║        ",
				"██║ ╚████║╚██████╔╝███████╗███████║███████╗██║  ██║███████╗",
				"╚═╝  ╚═══╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚══════╝",
			}
			local function get_header()
				local win_width = vim.api.nvim_win_get_width(0)
				local max_header_width = 0
				for _, line in ipairs(header_large) do
					max_header_width = math.max(max_header_width, #line)
				end
				if win_width >= max_header_width + 10 then
					return header_large
				else
					return header_small
				end
			end
			local header = {
				type = "text",
				val = get_header(),
				opts = {
					position = "center",
					hl = "Label",
				},
			}
			vim.api.nvim_create_autocmd("VimResized", {
				callback = function()
					if vim.bo.filetype == "alpha" then
						dashboard.section.header.val = get_header()
						require("alpha").redraw()
					end
				end,
			})
			-- footer
			local footer = {
				type = "text",
				val = {
					"yanosea.org",
				},
				opts = {
					position = "center",
					hl = "Number",
				},
			}
			-- buttons
			local icons = require("utils.icons").icons
			dashboard.section.buttons.val = {
				dashboard.button("n", icons.ui.NewFile .. "  new file", "<CMD>ene!<CR>"),
				dashboard.button("f", icons.ui.FindFile .. "  find file", "<CMD>Telescope find_files<CR>"),
				dashboard.button("t", icons.ui.FindText .. "  find text", "<CMD>Telescope live_grep<CR>"),
				dashboard.button("r", icons.ui.History .. "  recent files", "<CMD>Telescope oldfiles<CR>"),
				dashboard.button(
					"e",
					icons.ui.Telescope .. "  explorer",
					"<CMD>Telescope file_browser cwd=" .. vim.fn.expand("%:p:h") .. "<CR>"
				),
				dashboard.button("g", icons.git.Git .. "  lazygit", "<CMD>lua ToggleLazyGit()<CR>"),
				dashboard.button("l", icons.misc.Lazy .. "  lazy", "<CMD>Lazy<CR>"),
				dashboard.button("m", icons.misc.Mason .. "  mason lsp", "<CMD>Mason<CR>"),
				dashboard.button("T", icons.ui.Tree .. "  sync tree-sitter parser", "<CMD>TSUpdate<CR>"),
				dashboard.button("q", icons.ui.Close .. "  quit", "<CMD>quit<CR>"),
			}
			-- layout
			dashboard.section.header = header
			dashboard.section.buttons.opts = {
				spacing = 1,
				hl_shortcut = "Include",
			}
			dashboard.section.footer = footer
			-- apply config
			dashboard.config.opts.noautocmd = true
			dashboard.config.layout = {
				{ type = "padding", val = 2 },
				dashboard.section.header,
				{ type = "padding", val = 2 },
				dashboard.section.buttons,
				{ type = "padding", val = 2 },
				dashboard.section.footer,
			}
			require("alpha").setup(dashboard.config)
		end,
	},
}
