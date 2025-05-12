-- LuaSnipプラグイン
return {
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    event = "InsertEnter",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local luasnip = require("luasnip")

      -- 基本設定
      luasnip.config.set_config({
        history = true,
        updateevents = "TextChanged,TextChangedI",
        enable_autosnippets = true,
        ext_opts = {
          [require("luasnip.util.types").choiceNode] = {
            active = {
              virt_text = { { "●", "GruvboxOrange" } },
            },
          },
        },
      })

      -- スニペットパスの設定
      local snippet_path = vim.fn.stdpath("config") .. "/snippets"

      -- スニペットローダー設定
      local function load_snippets()
        require("luasnip.loaders.from_lua").lazy_load({
          paths = snippet_path,
        })

        -- friendly-snippetsの読み込み
        require("luasnip.loaders.from_vscode").lazy_load({
          paths = vim.fn.stdpath("data") .. "/lazy/friendly-snippets",
        })

        -- 追加のスニペットソース
        require("luasnip.loaders.from_vscode").lazy_load()
        require("luasnip.loaders.from_snipmate").lazy_load()
      end

      load_snippets()

      -- キーマップ設定
      vim.keymap.set({ "i", "s" }, "<C-n>", function()
        if luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        end
      end, { silent = true, desc = "luasnip forward" })

      vim.keymap.set({ "i", "s" }, "<C-p>", function()
        if luasnip.jumpable(-1) then
          luasnip.jump(-1)
        end
      end, { silent = true, desc = "luasnip backward" })

      vim.keymap.set({ "i", "s" }, "<C-l>", function()
        if luasnip.choice_active() then
          luasnip.change_choice(1)
        end
      end, { silent = true, desc = "luasnip next choice" })
    end,
  },
}
