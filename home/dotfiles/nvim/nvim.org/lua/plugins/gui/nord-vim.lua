return {
  {
    -- https://github.com/arcticicestudio/nord-vim
    "arcticicestudio/nord-vim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme nord]])
      vim.api.nvim_set_hl(0, "FloatBorder", { link = "Normal" })
      vim.api.nvim_set_hl(0, "Normal", { ctermbg = "none" })
      vim.api.nvim_set_hl(0, "NonText", { ctermbg = "none" })
      vim.api.nvim_set_hl(0, "LineNr", { ctermbg = "none" })
      vim.api.nvim_set_hl(0, "Folded", { ctermbg = "none" })
      vim.api.nvim_set_hl(0, "Folded", { ctermbg = "none" })
      vim.api.nvim_set_hl(0, "EndOfBuffer", { ctermbg = "none" })
    end,
  },
}
