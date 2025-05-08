-- render markdown
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
        heading = {
          position = "inline",
        },
        code = {
          left_pad = 2,
          right_pad = 4,
          highlight = "RenderMarkdownCode",
          highlight_inline = "RenderMarkdownCodeInline",
        },
        sign = {
          enabled = false,
        },
        file_types = {
          "Avante",
          "markdown",
        },
      })
    end,
  },
}
