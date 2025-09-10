-- typescript language server
local M = {}

function M.setup()
	vim.lsp.config("ts_ls", {
		root_dir = function(bufnr, on_dir)
			local buf_name = vim.fn.bufname(bufnr)
			local buf_dir = vim.fn.fnamemodify(buf_name, ":p:h")
			-- check if deno project
			local current_dir = buf_dir
			while current_dir ~= "/" do
				if
					vim.fn.filereadable(current_dir .. "/deno.json") == 1
					or vim.fn.filereadable(current_dir .. "/deno.jsonc") == 1
				then
					return
				end
				current_dir = vim.fn.fnamemodify(current_dir, ":h")
			end
			-- check if node project
			current_dir = buf_dir
			while current_dir ~= "/" do
				if
					vim.fn.filereadable(current_dir .. "/package.json") == 1
					or vim.fn.filereadable(current_dir .. "/tsconfig.json") == 1
					or vim.fn.filereadable(current_dir .. "/jsconfig.json") == 1
				then
					on_dir(current_dir)
					return
				end
				current_dir = vim.fn.fnamemodify(current_dir, ":h")
			end
		end,
		settings = {
			typescript = {
				inlayHints = {
					includeInlayParameterNameHints = "all",
					includeInlayParameterNameHintsWhenArgumentMatchesName = false,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayEnumMemberValueHints = true,
				},
			},
			javascript = {
				inlayHints = {
					includeInlayParameterNameHints = "all",
					includeInlayParameterNameHintsWhenArgumentMatchesName = false,
					includeInlayFunctionParameterTypeHints = true,
					includeInlayVariableTypeHints = true,
					includeInlayPropertyDeclarationTypeHints = true,
					includeInlayFunctionLikeReturnTypeHints = true,
					includeInlayEnumMemberValueHints = true,
				},
			},
		},
	})
end

return M
