-- clear existing autocommands first
vim.api.nvim_clear_autocmds({})
-- restore last cursor position
vim.api.nvim_create_autocmd("BufRead", {
	desc = "restore last cursor position",
	pattern = "*",
	callback = function(opts)
		vim.api.nvim_create_autocmd("BufWinEnter", {
			once = true,
			buffer = opts.buf,
			callback = function()
				local ft = vim.bo[opts.buf].filetype
				local last_known_line = vim.api.nvim_buf_get_mark(opts.buf, '"')[1]
				if
					not (ft:match("commit") and ft:match("rebase"))
					and last_known_line > 1
					and last_known_line <= vim.api.nvim_buf_line_count(opts.buf)
				then
					vim.api.nvim_feedkeys([[g`"]], "nx", false)
				end
			end,
		})
	end,
})
-- format on save
vim.api.nvim_create_autocmd("BufWritePre", {
	desc = "format on save",
	pattern = "*",
	callback = function()
		-- check if the file is a markdown file
		local markdown_exts = { md = true, mdx = true }
		local file_ext = vim.fn.expand("%:e")
		-- if the file is not a markdown file, remove trailing whitespace
		if not markdown_exts[file_ext] then
			-- remove trailing whitespace
			vim.cmd([[%s/\s\+$//e]])
		end
		-- format the buffer
		require("plugins.languages.lsp.utils.formatter").setup_format_on_save_all()
	end,
})
-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	desc = "highlight on yank",
	pattern = "*",
	callback = function()
		vim.hl.on_yank({ higroup = "Search", timeout = 100 })
	end,
})
-- define a group for directory opened for lir.nvim (netrw alternative)
vim.api.nvim_create_autocmd("BufEnter", {
	group = vim.api.nvim_create_augroup("_dir_opened", { clear = true }),
	nested = true,
	callback = function(args)
		local bufname = vim.api.nvim_buf_get_name(args.buf)
		local stat = vim.loop.fs_stat(bufname)
		if stat and stat.type == "directory" then
			vim.api.nvim_del_augroup_by_name("_dir_opened")
			vim.cmd("do User DirOpened")
			vim.api.nvim_exec_autocmds(args.event, { buffer = args.buf, data = args.data })
		end
	end,
})
-- show winbar for terminal buffers
vim.api.nvim_create_autocmd("TermOpen", {
	desc = "terminal buffer winbar",
	pattern = "*",
	callback = function()
		vim.wo.winbar = "  TERMINAL"
		vim.wo.number = false
		vim.wo.relativenumber = false
		vim.wo.winhighlight = "Normal:TerminalNormal,NormalNC:TerminalNormal"
	end,
})
-- auto reload files changed outside of nvim
vim.api.nvim_create_autocmd({ "WinEnter", "FocusGained", "BufEnter" }, {
	pattern = "*",
	command = "checktime",
})
