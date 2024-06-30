return {
  {
    -- https://github.com/windwp/nvim-ts-autotag
    "windwp/nvim-ts-autotag",
    lazy = true,
    event = "InsertEnter",
    config = true,
    init = function()
      require("nvim-ts-autotag").setup({})
    end,
  },
}
