-- automatically adjusts shiftwidth and expandtab
table.insert(lvim.plugins, {
  "tpope/vim-sleuth",
  event = { "BufReadPost", "BufNewFile" },
})
