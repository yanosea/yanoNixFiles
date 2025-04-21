-- japanese input method
return {
  {
    "vim-skk/skkeleton",
    event = "VeryLazy",
    dependencies = { "vim-denops/denops.vim" },
    config = function()
      local dictionaries = {}
      local handle = io.popen("ls $XDG_DATA_HOME/skk/*")
      if handle then
        for file in handle:lines() do
          table.insert(dictionaries, file)
        end
        handle:close()
      end
      local src = { "skk_dictionary", "google_japanese_input" }
      vim.api.nvim_create_autocmd("User", {
        pattern = "skkeleton-initialize-pre",
        callback = function()
          vim.fn["skkeleton#config"]({
            eggLikeNewline = true,
            globalDictionaries = dictionaries,
            immediatelyCancel = false,
            registerConvertResult = true,
            showCandidatesCount = 1,
            sources = src,
            userDictionary = os.getenv("XDG_STATE_HOME") .. "/skk/.skkeleton",
          })
          vim.fn["skkeleton#register_keymap"]("henkan", "<Esc>", "cancel")
        end,
      })

      vim.keymap.set("i", "<C-j>", "<Plug>(skkeleton-toggle)", { silent = true, desc = "Toggle skkeleton" })
      vim.keymap.set("c", "<C-j>", "<Plug>(skkeleton-toggle)", { silent = true, desc = "Toggle skkeleton" })
    end,
  },
}
