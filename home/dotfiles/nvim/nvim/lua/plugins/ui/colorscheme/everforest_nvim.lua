-- everforest colorscheme
return {
  {
    "neanias/everforest-nvim",
    lazy = true,
    event = "VimEnter",
    config = function()
      -- set neovim colorscheme
      vim.cmd("colorscheme everforest")
    end,
  }
}
