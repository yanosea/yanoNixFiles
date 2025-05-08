-- highlight pairs and extend % key to jump between matching pairs
return {
  {
    "andymass/vim-matchup",
    keys = { "%" },
    config = function()
      -- matchup matchparen offscreen method
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end,
  },
}
