-- define lsp keymaps
local M = {}
M.setup = function()
	-- show hover
	vim.keymap.set("n", "K", "<CMD>lua vim.lsp.buf.hover()<CR>", { desc = "show hover", silent = true })
	-- move to definition
	vim.keymap.set("n", "gd", "<CMD>lua vim.lsp.buf.definition()<CR>", { desc = "go to definition", silent = true })
	-- move to declaration
	vim.keymap.set("n", "gD", "<CMD>lua vim.lsp.buf.declaration()<CR>", { desc = "go to declaration", silent = true })
	-- move to references
	vim.keymap.set("n", "gr", "<CMD>lua vim.lsp.buf.references()<CR>", { desc = "go to references", silent = true })
	-- move to implementation
	vim.keymap.set(
		"n",
		"gI",
		"<CMD>lua vim.lsp.buf.implementation()<CR>",
		{ desc = "go to implementation", silent = true }
	)
	-- show signature help
	vim.keymap.set(
		"n",
		"gs",
		"<CMD>lua vim.lsp.buf.signature_help()<CR>",
		{ desc = "show signature help", silent = true }
	)
	-- show line diagnostics
	vim.keymap.set("n", "gl", function()
		local float = vim.diagnostic.config().float
		if float then
			local config = type(float) == "table" and float or {}
			config.scope = "line"
			vim.diagnostic.open_float(config)
		end
	end, { desc = "show line diagnostics", silent = true })
end
return M
