-- colorschemes
lvim.plugins = lvim.plugins or {}
table.insert(lvim.plugins, {
  -- additional colorschemes
  "arcticicestudio/nord-vim",
  "neanias/everforest-nvim",
})
-- default colorscheme
lvim.colorscheme = "tokyonight"
-- change colorscheme keymap
-- <C-c>f everforest
vim.keymap.set(
  "n",
  "<C-c>f",
  "<CMD>colorscheme everforest<CR>",
  { silent = true, desc = "Toggle colorscheme Everforest" }
)
-- <C-c>n nord
vim.keymap.set("n", "<C-c>n", "<CMD>colorscheme nord<CR>", { silent = true, desc = "Toggle colorscheme Nord" })
-- <C-c>l lunar
vim.keymap.set("n", "<C-c>l", "<CMD>colorscheme lunar<CR>", { silent = true, desc = "Toggle colorscheme Lunar" })
-- <C-c>t tokyonight
vim.keymap.set(
  "n",
  "<C-c>t",
  "<CMD>colorscheme tokyonight<CR>",
  { silent = true, desc = "Toggle colorscheme TokyoNight" }
)
