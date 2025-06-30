-- bufferline config
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>b)
return {
	{
		"akinsho/bufferline.nvim",
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local colors = require("utils.colors").colors
			local icons = require("utils.icons").icons
			-- set highlights for pin icon
			vim.api.nvim_set_hl(0, "BufferlinePinnedIcon", { fg = colors.Red, bold = true })
			-- bufferline.nvim config
			require("bufferline").setup({
				options = {
					highlights = {
						background = {
							italic = true,
						},
						buffer_selected = {
							bold = true,
						},
					},
					diagnostics = "nvim_lsp",
					diagnostics_update_in_insert = false,
					diagnostics_indicator = function(count, _, diagnostics_dict, _)
						if next(diagnostics_dict) then
							local s = ""
							for e, n in pairs(diagnostics_dict) do
								local sym = e == "error" and icons.diagnostics.BoldError
									or (
										e == "warning" and icons.diagnostics.BoldWarning
										or (
											e == "info" and icons.diagnostics.BoldInformation
											or icons.diagnostics.BoldHint
										)
									)
								s = s .. sym .. " " .. n .. " "
							end
							return s
						else
							return count > 0 and " " .. icons.diagnostics.BoldQuestion .. count or ""
						end
					end,
					groups = {
						items = {
							require("bufferline.groups").builtin.pinned:with({
								icon = " " .. "%#BufferlinePinnedIcon#" .. icons.misc.Pin .. "%*",
							}),
						},
					},
					offsets = {
						{
							filetype = "undotree",
							text = "Undotree",
							highlight = "PanelHeading",
							padding = 1,
						},
						{
							filetype = "NvimTree",
							text = "Explorer",
							highlight = "PanelHeading",
							padding = 1,
						},
						{
							filetype = "DiffviewFiles",
							text = "Diff View",
							highlight = "PanelHeading",
							padding = 1,
						},
						{
							filetype = "flutterToolsOutline",
							text = "Flutter Outline",
							highlight = "PanelHeading",
							padding = 1,
						},
						{
							filetype = "lazy",
							text = "Lazy",
							highlight = "PanelHeading",
							padding = 1,
						},
					},
					separator_style = "slope",
					show_buffer_close_icons = false,
					show_buffer_icons = true,
				},
			})
		end,
	},
}
