-- preferences
-- encoding
vim.opt.encoding = "utf-8"
vim.fileencoding = "utf-8"
vim.scriptencoding = "utf-8"
-- lang
vim.opt.helplang = "ja"
-- backup file
vim.opt.backup = false
-- swap file
vim.opt.swapfile = false
-- recovery time
vim.opt.updatetime = 200
-- line number
vim.opt.number = true
-- highlight current line
vim.opt.cursorline = true
-- cuesor position
vim.opt.ruler = true
-- sign column
vim.opt.signcolumn = "yes"
-- invisible character
vim.opt.list = true
vim.opt.listchars = { tab = "▸ ", trail = "⋅", nbsp = "␣", extends = "❯", precedes = "❮" }
-- status line
vim.opt.laststatus = 3
-- gui setting
vim.opt.guifont = { "PlemolJP Console NF" }
vim.opt.guifontwide = { "PlemolJP Console NF" }
vim.opt.termguicolors = true
vim.opt.mouse = ""
vim.opt.guicursor:append("i:block,a:-blinkwait175-blinkoff150-blinkon175")
-- search
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.cmd([[set noignorecase]])
vim.cmd([[set nowrapscan]])
-- command history
vim.opt.history = 1000
-- complement
vim.opt.wildmenu = true
vim.opt.completeopt = "menuone,noinsert"
-- indent
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
-- window split
vim.opt.splitbelow = true
vim.opt.splitright = true
-- syntax highlight
vim.opt.syntax = "enable"
-- clipboaed
vim.opt.clipboard:append("unnamedplus")
-- ignore auto format
vim.api.nvim_create_user_command("W", "noautocmd w", {})
vim.api.nvim_create_user_command("Wq", "noautocmd wq", {})
-- nowrap
vim.opt.wrap = false
