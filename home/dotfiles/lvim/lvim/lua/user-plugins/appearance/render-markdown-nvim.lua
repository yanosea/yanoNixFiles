-- render markdown
table.insert(lvim.plugins, {
  "MeanderingProgrammer/render-markdown.nvim",
  event = { "BufRead", "BufEnter" },
  init = function()
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
