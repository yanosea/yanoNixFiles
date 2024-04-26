return {
  {
    -- https://github.com/VidocqH/lsp-lens.nvim
    "VidocqH/lsp-lens.nvim",
    lazy = false,
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
  },
}
