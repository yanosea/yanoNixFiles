-- keymaps
local key = require("helper.key")
-- remap space as leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "
-- normal
-- hide highlight search
vim.keymap.set("n", "<ESC>", "<CMD>nohlsearch<CR>", { silent = true, desc = "Hide highlight" })
-- line
vim.keymap.set("n", "j", "gj")
vim.keymap.set("n", "k", "gk")
vim.keymap.set("n", "gj", "j")
vim.keymap.set("n", "gk", "k")
-- tab
vim.keymap.set(
  "n",
  key.ctrl_with_leader_keymap_set(key.ctrl_prefix, "k"),
  "<CMD>tabprevious<CR>",
  { desc = "Move previous tab" }
)
vim.keymap.set(
  "n",
  key.ctrl_with_leader_keymap_set(key.ctrl_prefix, "j"),
  "<CMD>tabnext<CR>",
  { desc = "Move next tab" }
)
vim.keymap.set(
  "n",
  key.ctrl_with_leader_keymap_set(key.ctrl_prefix, "t"),
  "<CMD>tabnew<CR>",
  { desc = "New empty tab" }
)
vim.keymap.set("n", key.ctrl_with_leader_keymap_set(key.ctrl_prefix, "c"), "<CMD>tabclose<CR>", { desc = "Close tab" })
-- buffer
vim.keymap.set("n", key.ctrl_keymap_set(key.ctrl_prefix, "k"), "<CMD>bprevious<CR>", { desc = "Move previous buffer" })
vim.keymap.set("n", key.ctrl_keymap_set(key.ctrl_prefix, "j"), "<CMD>bnext<CR>", { desc = "Move next buffer" })
vim.keymap.set("n", key.ctrl_keymap_set(key.ctrl_prefix, "t"), "<CMD>enew<CR>", { desc = "New empty buffer" })
vim.keymap.set("n", key.ctrl_keymap_set(key.ctrl_prefix, "c"), "<CMD>bd<CR>", { desc = "Close buffer" })
-- visual
vim.keymap.set("v", "<C-p>", '"0p<CR>', { desc = "Paste in a row" })
