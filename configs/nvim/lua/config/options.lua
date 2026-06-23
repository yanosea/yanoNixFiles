-- vim options
-- define encoding
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.scriptencoding = "utf-8"
-- set help language
vim.opt.helplang = "ja"
-- disable backup file
vim.opt.backup = false
-- disable swap file
vim.opt.swapfile = false
-- show line number
vim.opt.number = true
-- show relative line number
vim.opt.relativenumber = true
-- highlight current line
vim.opt.cursorline = true
-- show cursor position
vim.opt.ruler = true
-- always show sign coolumn
vim.opt.signcolumn = "yes"
-- invisible characters
vim.opt.list = true
vim.opt.listchars = { tab = "▸ ", trail = "⋅", nbsp = "␣", extends = "❯", precedes = "❮" }
-- always show status line
vim.opt.laststatus = 3
-- disable wrapping
vim.opt.wrap = false
-- gui setting
vim.opt.guifont = { "PlemolJP Console NF" }
vim.opt.guifontwide = { "PlemolJP Console NF" }
vim.opt.termguicolors = true
vim.opt.mouse = "" -- disable mouse
vim.opt.guicursor:append("i:block,a:-blinkwait175-blinkoff150-blinkon175") -- cursor style (all modes : block, blink)
-- search
vim.opt.hlsearch = true -- highlight search results
vim.opt.ignorecase = false -- ignore case when searching
vim.opt.smartcase = true -- ignore case when searching if all lowercase
vim.opt.incsearch = true -- show search results as you type
vim.opt.wrapscan = false -- don't wrap search results
-- how many lines of command history to keep
vim.opt.history = 1000
-- complement
vim.opt.wildmenu = true -- show command line completion
vim.opt.completeopt = "menuone,noinsert" -- show completion popup even if there's only one match
-- indent
vim.opt.autoindent = true -- enable auto indent
vim.opt.smartindent = true -- enable indent based on syntax
vim.opt.expandtab = true -- convert tabs to spaces
vim.opt.tabstop = 2 -- number of spaces to use for a tab
vim.opt.shiftwidth = 2 -- number of spaces to use for auto indent
-- window split
vim.opt.splitbelow = true -- put new windows below the current one
vim.opt.splitright = true -- put new windows to the right of the current one
-- set shell to the user's default shell
vim.opt.shell = vim.env.SHELL or "bash"
-- enable syntax highlighting
vim.opt.syntax = "enable"
-- enable system clipboard
vim.opt.clipboard:append("unnamedplus")
-- disable line move with h and l
vim.opt.whichwrap = vim.opt.whichwrap - "h" - "l"
-- display
vim.opt.cmdheight = 0 -- hide command line (bottom of the screen) because of using noice.nvim
vim.opt.display = "lastline" -- show last line of the screen
-- persist undo
vim.opt.undofile = true
-- suppress noisy LSP log messages
local lsp_log_suppress = {
	"chat-lib-tokenizer",
	"reading on stdin, writing on stdout",
	"connections closed",
	"connection is closed",
	"document not found: term://",
}
vim.lsp.log.set_format_func(function(level, ...)
	if vim.log.levels[level] ~= nil and vim.log.levels[level] < vim.lsp.log.get_level() then
		return nil
	end
	local argc = select("#", ...)
	for i = 1, argc do
		local arg = select(i, ...)
		if type(arg) == "string" then
			for _, pattern in ipairs(lsp_log_suppress) do
				if arg:find(pattern, 1, true) then
					return nil
				end
			end
		end
	end
	local info = debug.getinfo(2, "Sl")
	local header = string.format("[%s][%s] %s:%s", level, os.date("%F %H:%M:%S"), info.short_src, info.currentline)
	local parts = { header }
	for i = 1, argc do
		local arg = select(i, ...)
		table.insert(parts, arg == nil and "nil" or vim.inspect(arg, { newline = " ", indent = "" }))
	end
	return table.concat(parts, "\t") .. "\n"
end)
