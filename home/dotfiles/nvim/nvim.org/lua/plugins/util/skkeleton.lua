return {
  {
    -- https://github.com/vim-skk/skkeleton
    "vim-skk/skkeleton",
    lazy = false,
    -- https://github.com/vim-denops/denops.vim
    dependencies = { "vim-denops/denops.vim" },
    init = function()
      vim.keymap.set("i", "<C-Space>", "<Plug>(skkeleton-toggle)")
      vim.keymap.set("c", "<C-Space>", "<Plug>(skkeleton-toggle)")
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
    end,
  },
}
