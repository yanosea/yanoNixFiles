-- clear existing autocommands
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
-- remove trailing whitespace on save except for markdown files
vim.api.nvim_create_autocmd("BufWritePre", {
  desc = "remove trailing whitespace on save except for markdown files",
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
  end,
})
-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "highlight on yank",
  pattern = "*",
  callback = function()
    vim.highlight.on_yank { higroup = "Search", timeout = 100 }
  end,
})
