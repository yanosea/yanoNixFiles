-- render markdown
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    lazy = true,
    ft = { "markdown", "Avante" },
    opts = {
      file_types = { "markdown", "Avante" },
    },
    config = function()
      require("render-markdown").setup({
        -- render-markdown.nvim config
        file_types = {
          "Avante",
          "markdown",
        },
        render_modes = { "n", "c", "t" },
        -- components config
        heading = {
          border = true,
          border_virtual = true,
          width = "block",
          min_width = 30,
        },
        code = {
          width = "block",
          right_pad = 2,
        },
      })
    end,
  },
}
