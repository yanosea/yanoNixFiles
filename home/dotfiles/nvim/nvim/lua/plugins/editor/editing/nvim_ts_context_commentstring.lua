--  set the commentstring option in Neovim based on the context of the code being edited
return {
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    event = { "BufReadPost", "BufNewFile" },
  },
}
