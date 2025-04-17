-- autocommands config
lvim.autocommands = {
  -- remove trailing whitespace on save except for markdown files
  {
    "BufWritePre",
    {
      pattern = { "*" },
      callback = function()
        local file_ext = vim.fn.expand("%:e")
        if file_ext ~= "mdx" and file_ext ~= "md" then
          vim.cmd([[%s/\s\+$//e]])
        end
      end,
    },
  },
  -- restore last cursor position
  {
    "BufRead",
    {
      pattern = { "*" },
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
    },
  },
}
