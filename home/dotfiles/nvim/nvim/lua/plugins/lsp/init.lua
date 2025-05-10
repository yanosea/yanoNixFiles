-- lsp config
return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local ensure_installed = {
        "lua_ls",
      }
      require("mason").setup()
      require("mason-lspconfig").setup({
        automatic_installation = true,
        ensure_installed = ensure_installed,
      })
      local colors = {
        bg = "#2b3339", -- everforest bg
        fg = "#d3c6aa", -- everforest fg
        yellow = "#dbbc7f", -- everforest yellow
        cyan = "#83c092", -- everforest aqua
        darkblue = "#1e2326", -- everforest bg_dim
        green = "#a7c080", -- everforest green
        orange = "#e69875", -- everforest orange
        violet = "#9fe3d3", -- everforest teal
        magenta = "#d699b6", -- everforest purple
        purple = "#b67996", -- everforest magenta
        blue = "#7fbbb3", -- everforest blue
        red = "#e67e80", -- everforest red
      }
      local icons = {
        diagnostics = {
          BoldError = "",
          BoldWarning = "",
          BoldInformation = "",
          BoldHint = "",
        },
      }
      vim.diagnostic.config({
        virtual_text = true,
        update_in_insert = false,
        underline = true,
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = icons.diagnostics.BoldError,
            [vim.diagnostic.severity.WARN] = icons.diagnostics.BoldWarning,
            [vim.diagnostic.severity.INFO] = icons.diagnostics.BoldInformation,
            [vim.diagnostic.severity.HINT] = icons.diagnostics.BoldHint,
          },
          texthl = {
            [vim.diagnostic.severity.ERROR] = { fg = colors.red },
            [vim.diagnostic.severity.WARN] = { fg = colors.yellow },
            [vim.diagnostic.severity.INFO] = { fg = colors.blue },
            [vim.diagnostic.severity.HINT] = { fg = colors.green },
          },
        },
        float = {
          source = "always",
          border = "rounded",
          header = "",
          prefix = "",
        },
      })
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              globals = {
                "nvim",
                "vim",
              },
            },
          },
        },
      })
      vim.lsp.enable(ensure_installed)
    end,
  },
}
