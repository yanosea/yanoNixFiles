-- efm lsp config
return {
  {
    "neovim/nvim-lspconfig",
    lazy = true,
    event = "VeryLazy",
    config = function()
      local lspconfig = require("lspconfig")
      lspconfig.efm.setup({
        init_options = { documentFormatting = true },
        filetypes = { "lua" },
        settings = {
          rootMarkers = { ".git/" },
          languages = {
            lua = {
              { formatCommand = "stylua --stdin-filepath ${INPUT}", formatStdin = true },
            },
          },
        },
      })
    end,
  }
}
