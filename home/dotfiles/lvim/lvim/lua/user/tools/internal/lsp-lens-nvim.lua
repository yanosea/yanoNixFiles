-- displaying reference and definition info upon functions
table.insert(lvim.plugins, {
  "VidocqH/lsp-lens.nvim",
  event = { "LspAttach" },
  config = function()
    require("lsp-lens").setup({
      enable = true,
      include_declaration = true,
      sections = {
        definition = true,
        references = true,
        implements = true,
      },
      ignore_filetype = {
        "prisma",
      },
    })
  end,
})
