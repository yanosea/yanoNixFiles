-- autocommands config
vim.cmd("autocmd!")
local autocmd = vim.api.nvim_create_autocmd
autocmd(
  -- remove trailing whitespace on save except for markdown files
  "BufWritePre",
  {
    pattern = { "*" },
    callback = function()
      local file_ext = vim.fn.expand("%:e")
      if file_ext ~= "mdx" and file_ext ~= "md" then
        vim.cmd([[%s/\s\+$//e]])
      end
    end,
  }
)
