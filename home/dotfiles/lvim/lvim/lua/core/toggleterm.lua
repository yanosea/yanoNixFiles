-- toggleterm config
-- keymap
vim.keymap.set("n", "<LEADER>t", "<CMD>ToggleTerm<CR>", { silent = true, desc = "ToggleTerm" })
-- direction
lvim.builtin.terminal.direction = "horizontal"
-- disable in insert mode
lvim.builtin.terminal.insert_mappings = false
