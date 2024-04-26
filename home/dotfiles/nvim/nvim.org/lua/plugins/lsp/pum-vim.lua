return {
  {
    -- https://github.com/Shougo/pum.vim
    "Shougo/pum.vim",
    config = function()
      vim.fn["pum#set_option"]({
        auto_select = true,
        padding = true,
        border = "none",
        preview = false,
        scrollbar_char = "▋",
      })

      local opts = { silent = true, noremap = true }
      vim.keymap.set("i", "<DOWN>", "<CMD>call pum#map#select_relative(+1)<CR>", opts)
      vim.keymap.set("i", "<UP>", "<CMD>call pum#map#select_relative(-1)<CR>", opts)
      vim.keymap.set("i", "<TAB>", "<CMD>call pum#map#confirm()<CR>", opts)
      vim.keymap.set("i", "<C-e>", "<CMD>call pum#map#cancel()<CR>", opts)
    end,
  },
}
