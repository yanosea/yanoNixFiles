return {
  {
    -- https://github.com/akinsho/toggleterm.nvim
    "akinsho/toggleterm.nvim",
    lazy = true,
    keys = { "<LEADER>t" },
    opts = function()
      require("toggleterm").setup({
        hide_numbers = true,
        shade_filetypes = {},
        autochdir = false,
        start_in_insert = true,
        insert_mappings = true,
        terminal_mappings = true,
        persist_size = true,
        persist_mode = true,
        direction = "horizontal",
        close_on_exit = true,
        shell = vim.o.shell,
        auto_scroll = true,
      })
      vim.keymap.set("n", "<LEADER>t", "<CMD>ToggleTerm<CR>", { noremap = true })
      vim.api.nvim_create_autocmd({ "TermEnter" }, {
        callback = function()
          for _, buffers in ipairs(vim.fn.getbufinfo()) do
            local filetype = vim.bo[buffers.bufnr].filetype
            if filetype == "toggleterm" then
              vim.api.nvim_create_autocmd({ "BufWriteCmd", "FileWriteCmd", "FileAppendCmd" }, {
                buffer = buffers.bufnr,
                command = "q!",
              })
            end
          end
        end,
      })
    end,
  },
}
