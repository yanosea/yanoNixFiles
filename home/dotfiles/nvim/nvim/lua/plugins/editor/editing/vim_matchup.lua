-- highlight pairs and extend % key to jump between matching pairs
return {
  {
    "andymass/vim-matchup",
    lazy = true,
    event = "VeryLazy",
    init = function()
      -- matchup matchparen offscreen method
      vim.g.matchup_matchparen_offscreen = { method = "popup" }
    end,
  },
}
