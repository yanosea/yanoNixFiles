-- luasnip config
return {
	{
		"L3MON4D3/LuaSnip",
		version = "v2.*",
		dependencies = {
			"rafamadriz/friendly-snippets",
		},
		lazy = true,
		event = "InsertEnter",
		config = function()
			local icons = require("utils.icons").icons
			local luasnip = require("luasnip")
			-- luasnip config
			luasnip.config.set_config({
				history = true,
				update_events = "TextChanged,TextChangedI",
				enable_autosnippets = true,
				ext_opts = {
					[require("luasnip.util.types").choiceNode] = {
						active = {
							virt_text = { { icons.ui.Circle, "GruvboxOrange" } },
						},
					},
				},
			})
			-- load snippets
			local snippet_path = vim.fn.stdpath("config") .. "/snippets"
			require("luasnip.loaders.from_lua").lazy_load({
				paths = { snippet_path },
			})
			require("luasnip.loaders.from_vscode").lazy_load({
				paths = { vim.fn.stdpath("data") .. "/lazy/friendly-snippets" },
			})
			require("luasnip.loaders.from_snipmate").lazy_load()
			-- keymaps
			vim.keymap.set({ "i", "s" }, "<C-n>", function()
				if luasnip.expand_or_jumpable() then
					luasnip.expand_or_jump()
				end
			end, { desc = "luasnip forward", silent = true })
			vim.keymap.set({ "i", "s" }, "<C-p>", function()
				if luasnip.jumpable(-1) then
					luasnip.jump(-1)
				end
			end, { desc = "luasnip backward", silent = true })
			vim.keymap.set({ "i", "s" }, "<C-l>", function()
				if luasnip.choice_active() then
					luasnip.change_choice(1)
				end
			end, { desc = "luasnip next choice", silent = true })
		end,
	},
}
