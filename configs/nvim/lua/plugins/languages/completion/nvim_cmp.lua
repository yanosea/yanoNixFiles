-- completion config
return {
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			"chrisgrieser/cmp-nerdfont",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-calc",
			"hrsh7th/cmp-cmdline",
			"hrsh7th/cmp-emoji",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"ray-x/cmp-treesitter",
			"saadparwaiz1/cmp_luasnip",
			"zbirenbaum/copilot-cmp",
		},
		lazy = true,
		event = { "InsertEnter", "CmdlineEnter" },
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local cmp_window = require("cmp.config.window")
			local cmp_mapping = require("cmp.config.mapping")
			local icons = require("utils.icons").icons
			-- define jumpable function
			local function jumpable(dir)
				return luasnip.in_snippet() and luasnip.jumpable(dir)
			end
			-- define sources
			local source_names = {
				buffer = "(buffer)",
				calc = "(calc)",
				codeium = "(codeium)",
				copilot = "(copilot)",
				emoji = "(emoji)",
				luasnip = "(snippet)",
				nerdfont = "(nerdfont)",
				nvim_lsp = "(lsp)",
				nvim_lsp_signature_help = "(signature)",
				path = "(path)",
				treesitter = "(treesitter)",
			}
			-- define duplicates
			local duplicates = {
				buffer = true,
				path = true,
				nvim_lsp = false,
				luasnip = true,
			}
			-- nvim-cmp config
			cmp.setup({
				enabled = function()
					local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })
					if buftype == "prompt" then
						return false
					end
					return true
				end,
				confirm_opts = {
					behavior = cmp.ConfirmBehavior.Replace,
					select = false,
				},
				completion = {
					keyword_length = 1,
					completeopt = "menu,menuone,noselect",
				},
				sorting = {
					priority_weight = 2,
					comparators = {
						cmp.config.compare.exact,
						cmp.config.compare.score,
						cmp.config.compare.offset,
						cmp.config.compare.recently_used,
						cmp.config.compare.locality,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
				},
				experimental = {
					ghost_text = false,
					native_menu = false,
				},
				formatting = {
					fields = { "kind", "abbr", "menu" },
					max_width = 50,
					format = function(entry, vim_item)
						local colors = require("utils.colors").colors
						if #vim_item.abbr > 50 then
							vim_item.abbr = string.sub(vim_item.abbr, 1, 49) .. "…"
						end
						if icons then
							vim_item.kind = icons.kind[vim_item.kind] or vim_item.kind
							local source_icons = {
								buffer = icons.ui and icons.ui.Text,
								codeium = icons.misc and icons.misc.Robot,
								copilot = icons.git and icons.git.Octoface,
								emoji = icons.misc and icons.misc.Smiley,
							}
							local source_hl_groups = {
								buffer = "CmpItemKindText",
								codeium = "CmpItemKindCodeium",
								copilot = "CmpItemKindCopilot",
								emoji = "CmpItemKindEmoji",
							}
							if entry.source.name == "copilot" then
								vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = colors.Green })
							elseif entry.source.name == "codeium" then
								vim.api.nvim_set_hl(0, "CmpItemKindCodeium", { fg = colors.Blue })
							end
							if source_icons[entry.source.name] then
								vim_item.kind = source_icons[entry.source.name]
								vim_item.kind_hl_group = source_hl_groups[entry.source.name]
							end
						end
						vim_item.menu = source_names[entry.source.name] or entry.source.name
						vim_item.dup = duplicates[entry.source.name] and 1 or nil
						return vim_item
					end,
				},
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp_window.bordered(),
					documentation = cmp_window.bordered(),
				},
				sources = {
					-- ai completion sources (highest priority)
					{
						name = "codeium",
						max_item_count = 5,
						priority = 1000,
						group_index = 1,
					},
					{
						name = "copilot",
						max_item_count = 3,
						priority = 900,
						group_index = 1,
					},
					-- lsp and snippet sources (middle priority)
					{
						name = "nvim_lsp",
						priority = 800,
						group_index = 2,
						entry_filter = function(entry, ctx)
							local kind = require("cmp.types.lsp").CompletionItemKind[entry:get_kind()]
							if kind == "Snippet" and ctx.prev_context.filetype == "java" then
								return false
							end
							return true
						end,
					},
					{ name = "luasnip", priority = 700, group_index = 2 },
					{ name = "nvim_lsp_signature_help", priority = 650, group_index = 2 },
					-- other sources (lower priority)
					{ name = "buffer", priority = 500, group_index = 3 },
					{ name = "path", priority = 400, group_index = 3 },
					{ name = "calc", priority = 300, group_index = 3 },
					{ name = "treesitter", priority = 200, group_index = 3 },
					{ name = "emoji", priority = 100, group_index = 3 },
					{ name = "nerdfont", priority = 50, group_index = 3 },
				},
				mapping = cmp_mapping.preset.insert({
					["<Down>"] = cmp_mapping(
						cmp_mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
						{ "i" }
					),
					["<Up>"] = cmp_mapping(
						cmp_mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
						{ "i" }
					),
					["<C-y>"] = cmp_mapping({
						i = cmp_mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false }),
						c = function(fallback)
							if cmp.visible() then
								cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
							else
								fallback()
							end
						end,
					}),
					["<Tab>"] = cmp_mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						elseif jumpable(1) then
							luasnip.jump(1)
						else
							fallback()
						end
					end, { "i", "s" }),
					["<S-Tab>"] = cmp_mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
					["<C-Space>"] = cmp_mapping.complete(),
					["<C-e>"] = cmp_mapping.abort(),
					["<CR>"] = cmp_mapping(function(fallback)
						if not cmp.visible() then
							fallback()
							return
						end
						local confirm_opts = {
							behavior = cmp.ConfirmBehavior.Replace,
							select = false,
						}
						local entry = cmp.get_selected_entry()
						local is_copilot = entry and entry.source.name == "copilot"
						local is_codeium = entry and entry.source.name == "codeium"
						if is_copilot or is_codeium then
							confirm_opts.behavior = cmp.ConfirmBehavior.Replace
							confirm_opts.select = true
						elseif vim.api.nvim_get_mode().mode:sub(1, 1) == "i" then
							confirm_opts.behavior = cmp.ConfirmBehavior.Insert
						end
						if not cmp.confirm(confirm_opts) then
							fallback()
						end
					end),
				}),
			})
			-- command line setup
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "cmdline" },
					{ name = "path" },
				},
			})
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
				},
			})
		end,
	},
}
