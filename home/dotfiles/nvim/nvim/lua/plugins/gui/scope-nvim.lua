return {
  {
    -- https://github.com/tiagovla/scope.nvim
    "tiagovla/scope.nvim",
    lazy = false,
    init = function()
      require("scope").setup({})
    end,
  },
}
