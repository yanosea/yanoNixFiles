-- auto commands
vim.cmd("autocmd!")
local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
-- remove whitespace on save
autocmd("BufWritePre", {
  pattern = "*",
  command = "if expand('%:e') != 'mdx' | %s/\\s\\+$//e | endif",
})
-- open terminal with insert mode
autocmd("TermOpen", {
  pattern = "*",
  command = "startinsert",
})
-- highlight on yank
autocmd("TextYankPost", {
  group = augroup("highlight_yank", {}),
  pattern = "*",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})
-- prevent neovim from exiting with status code 134
autocmd({ "VimLeave" }, {
  callback = function()
    vim.cmd("sleep 1m")
  end,
})
-- disable highlight end of buffer
autocmd("BufEnter", {
  group = augroup("disable_end_of_buffer", {}),
  pattern = "*",
  command = "highlight link EndOfBuffer Ignore",
})
