-- clipboard sharing between WSL and Windows
if vim.fn.executable("win32yank.exe") ~= 0 then
	vim.g.clipboard = {
		name = "win32yank",
		copy = {
			["+"] = "win32yank.exe -i",
			["*"] = "win32yank.exe -i",
		},
		paste = {
			["+"] = "win32yank.exe -o",
			["*"] = "win32yank.exe -o",
		},
		cache_enable = 0,
	}
end
