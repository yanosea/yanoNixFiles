return {
  {
    --  https://github.com/andymass/vim-matchup
    "andymass/vim-matchup",
    lazy = false,
    config = function()
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end,
  },
}
