-- highlight pairs and extend % key to jump between matching pairs
table.insert(lvim.plugins, {
  "andymass/vim-matchup",
  keys = { "%" },
  config = function()
    vim.g.matchup_matchparen_offscreen = { method = "popup" }
  end,
})
