-- common keymaps config
-- leader key
vim.g.mapleader = "SPACE" and " "
-- local leader key
vim.g.maplocalleader = "\\"
-- move line up and down
vim.keymap.set("n", "j", "gj", { desc = "move down", silent = true })
vim.keymap.set("n", "k", "gk", { desc = "move up", silent = true })
vim.keymap.set("n", "gj", "j", { desc = "move down", silent = true })
vim.keymap.set("n", "gk", "k", { desc = "move up", silent = true })
-- window focus
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "focus left window", silent = true, noremap = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "focus down window", silent = true, noremap = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "focus up window", silent = true, noremap = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "focus right window", silent = true, noremap = true })
-- clear search highlight
vim.keymap.set("n", "<ESC>", "<CMD>nohlsearch<CR>", { desc = "clear search highlight", silent = true })
-- paste without affecting clipboard
vim.keymap.set("v", "p", '"_dP', { desc = "paste without affecting clipboard", silent = true })
