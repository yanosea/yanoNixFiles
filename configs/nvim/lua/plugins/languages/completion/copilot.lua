-- copilot config
return {
	{
		"zbirenbaum/copilot.lua",
		lazy = true,
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			-- override vim.ui.select to suppress monthly limit popups
			local original_ui_select = vim.ui.select
			vim.ui.select = function(items, opts, on_choice)
				-- check if this is a copilot monthly limit popup
				if
					opts
					and opts.prompt
					and (
						opts.prompt:match("monthly.*limit")
						or opts.prompt:match("usage.*limit")
						or opts.prompt:match("quota.*exceeded")
						or opts.prompt:match("reached.*limit")
						or opts.prompt:match("Upgrade.*plan")
					)
				then
					-- set flag for lualine to hide copilot status
					vim.g.copilot_monthly_limit_reached = true
					-- silently dismiss by selecting "Dismiss" option
					if on_choice then
						-- find dismiss option (usually option 2)
						for i, item in ipairs(items) do
							if tostring(item):match("Dismiss") or i == 2 then
								on_choice(item, i)
								return
							end
						end
						-- if no dismiss option found, just call with nil
						on_choice(nil, nil)
					end
					return
				end
				-- for other ui.select calls, use the original function
				return original_ui_select(items, opts, on_choice)
			end
			-- copilot.lua config
			require("copilot").setup({
				-- disable suggestion
				suggestion = { enabled = false },
				-- disable panel
				panel = { enabled = false },
			})
		end,
	},
}
