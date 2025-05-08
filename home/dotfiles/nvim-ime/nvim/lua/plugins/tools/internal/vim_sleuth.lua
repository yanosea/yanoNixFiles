-- automatically adjusts shiftwidth and expandtab
return {
  {
    "tpope/vim-sleuth",
    event = { "BufReadPost", "BufNewFile" },
  },
}
