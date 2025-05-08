-- translate text
return {
  {
    "skanehira/denops-translate.vim",
    dependencies = {
      "vim-denops/denops.vim"
    },
    lazy = true,
    event = "VeryLazy",
    init = function()
      -- keymaps
      -- visual mode mapping for selection translation
      vim.api.nvim_set_keymap(
        "v",
        "<LEADER>T",
        ":'<,'>Translate<CR>",
        { desc = "translate selection", silent = true, noremap = true }
      )
      -- normal mode mapping for line translation
      vim.api.nvim_set_keymap(
        "n",
        "<LEADER>T",
        "<CMD>Translate<CR>",
        { desc = "translate current line", silent = true, noremap = true }
      )
    end,
  },
}
