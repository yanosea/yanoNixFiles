-- common keymaps config
-- leader key
vim.g.mapleader = "space" and " "
-- local leader
vim.g.maplocalleader = "\\"
-- move line
vim.keymap.set("n", "j", "gj", { silent = true })
vim.keymap.set("n", "k", "gk", { silent = true })
vim.keymap.set("n", "gj", "j", { silent = true })
vim.keymap.set("n", "gk", "k", { silent = true })
-- buffer
vim.keymap.set("n", "<LEADER>bn", "<CMD>bnext<CR>", { desc = "switch to next buffer", silent = true  })
vim.keymap.set("n", "<LEADER>bb", "<CMD>bprevious<CR>", { desc = "switch to previous buffer", silent = true })
vim.keymap.set("n", "<LEADER>bc", "<CMD>bd<CR>", { desc = "close current buffer", silent = true })
-- clear search highlight
vim.keymap.set("n", "<ESC>", "<CMD>nohlsearch<CR>", { desc = "clear search highlight", silent = true })
-- paste without affecting clipboard
vim.keymap.set("v", "p", '"_dP', { desc = "paste without affecting clipboard", silent = true })
