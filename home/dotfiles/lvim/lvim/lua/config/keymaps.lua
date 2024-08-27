-- keymaps
-- hide highlight search
vim.keymap.set("n", "<ESC>", "<CMD>nohlsearch<CR>", { silent = true, desc = "No Highlight" })
-- paste without affecting clipboard in visual mode
vim.keymap.set("v", "p", '"_dP', { silent = true, desc = "Paste without affecting clipboard" })
