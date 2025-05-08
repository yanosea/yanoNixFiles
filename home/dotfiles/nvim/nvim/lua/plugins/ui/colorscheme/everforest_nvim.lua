-- everforest colorscheme
return {
  {
    "neanias/everforest-nvim",
    lazy = true,
    event = "UIEnter",
    config = function()
      -- set neovim colorscheme
      vim.cmd("colorscheme everforest")
    end,
  }
}
