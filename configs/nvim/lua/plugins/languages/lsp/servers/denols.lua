-- deno language server
local M = {}

function M.setup()
	vim.lsp.config("denols", {
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
					on_dir(current_dir)
					return
				end
				current_dir = vim.fn.fnamemodify(current_dir, ":h")
			end
		end,
		settings = {
			deno = {
				enable = true,
				lint = true,
				unstable = true,
				suggest = {
					completeFunctionCalls = false,
					names = true,
					paths = true,
					autoImports = true,
				},
			},
		},
		init_options = {
			lint = true,
		},
	})
end

return M
