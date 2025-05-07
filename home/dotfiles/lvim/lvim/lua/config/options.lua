-- vim options
-- encoding
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
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
-- cursor position
vim.opt.ruler = true
-- sign coolumn
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
vim.opt.ignorecase = false
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.wrapscan = false
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
-- shell
vim.opt.shell = os.getenv("SHELL")
-- syntax highlight
vim.opt.syntax = "enable"
-- clipboard
vim.opt.clipboard:append("unnamedplus")
-- ignore auto format
vim.api.nvim_create_user_command("W", "noautocmd w", {})
vim.api.nvim_create_user_command("Wq", "noautocmd wq", {})
-- disable line move with h and l
vim.opt.whichwrap = vim.opt.whichwrap - "h" - "l"
-- display
vim.opt.cmdheight = 0
vim.opt.display = "lastline"

-- lunarvim options
-- transparent window
-- lvim.transparent_window = true
-- format on save
lvim.format_on_save = true
-- hide highlight search
vim.keymap.set("n", "<ESC>", "<CMD>nohlsearch<CR>", { silent = true, desc = "No Highlight" })
-- paste without affecting clipboard in visual mode
vim.keymap.set("v", "p", '"_dP', { silent = true, desc = "Paste without affecting clipboard" })
