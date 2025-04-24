-- render markdown
table.insert(lvim.plugins, {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    file_types = { "markdown", "Avante" },
  },
  ft = { "markdown", "Avante" },
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
})
