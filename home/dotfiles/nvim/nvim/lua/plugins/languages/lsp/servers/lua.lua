return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "folke/neodev.nvim",
    },
    lazy = true,
    event = "VeryLazy",
    config = function()
      local helpers = require("plugins.languages.lsp.utils.helpers")
      local lspconfig = require("lspconfig")

      -- コンフィギュレーションのフック設定
      local original_on_new_config = lspconfig.lua_ls.document_config.on_new_config or function() end
      lspconfig.lua_ls.document_config.on_new_config = function(new_config, root_dir)
        original_on_new_config(new_config, root_dir)

        -- プラグインをワークスペースに追加
        local plugins = { "plenary.nvim", "telescope.nvim", "nvim-treesitter", "LuaSnip" }
        helpers.add_packages_to_workspace(plugins, new_config)
      end

      -- Lua LSP の詳細設定を適用
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            telemetry = { enable = false },
            runtime = {
              version = "LuaJIT",
              special = {
                reload = "require",
              },
            },
            diagnostics = {
              globals = {
                "vim",
                "nvim",
              },
            },
            workspace = helpers.default_workspace,
          },
        },
      })
    end,
  },
}
