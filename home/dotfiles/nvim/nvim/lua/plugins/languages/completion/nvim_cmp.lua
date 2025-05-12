-- nvim-cmp関連プラグイン
return {
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "saadparwaiz1/cmp_luasnip",
      "zbirenbaum/copilot-cmp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local cmp_window = require("cmp.config.window")
      local cmp_mapping = require("cmp.config.mapping")
      local icons = require("utils.icons").icons
      -- lvim.buildtin.cmp相当の設定を直接定義
      local has_words_before = function()
        local line, col = table.unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end

      -- jumpable関数の定義
      local function jumpable(dir)
        -- luasnipの再定義を避けるために別の変数名を使う
        local luasnip_status, luasnip_lib = pcall(require, "luasnip")
        if not luasnip_status then
          return false
        end

        local win_get_cursor = vim.api.nvim_win_get_cursor
        local get_current_buf = vim.api.nvim_get_current_buf

        -- 既存のLunarVimの実装をそのまま活用
        local function seek_luasnip_cursor_node()
          if not luasnip_lib.session.current_nodes then
            return false
          end

          local node = luasnip_lib.session.current_nodes[get_current_buf()]
          if not node then
            return false
          end

          local snippet = node.parent.snippet
          local exit_node = snippet.insert_nodes[0]

          local pos = win_get_cursor(0)
          pos[1] = pos[1] - 1

          -- exit early if we're past the exit node
          if exit_node then
            local exit_pos_end = exit_node.mark:pos_end()
            if (pos[1] > exit_pos_end[1]) or (pos[1] == exit_pos_end[1] and pos[2] > exit_pos_end[2]) then
              snippet:remove_from_jumplist()
              luasnip_lib.session.current_nodes[get_current_buf()] = nil

              return false
            end
          end

          node = snippet.inner_first:jump_into(1, true)
          while node ~= nil and node.next ~= nil and node ~= snippet do
            local n_next = node.next
            local next_pos = n_next and n_next.mark:pos_begin()
            local candidate = n_next ~= snippet and next_pos and (pos[1] < next_pos[1])
              or (pos[1] == next_pos[1] and pos[2] < next_pos[2])

            -- Past unmarked exit node, exit early
            if n_next == nil or n_next == snippet.next then
              snippet:remove_from_jumplist()
              luasnip_lib.session.current_nodes[get_current_buf()] = nil

              return false
            end

            if candidate then
              luasnip_lib.session.current_nodes[get_current_buf()] = node
              return true
            end

            local ok
            ok, node = pcall(node.jump_from, node, 1, true) -- no_move until last stop
            if not ok then
              snippet:remove_from_jumplist()
              luasnip_lib.session.current_nodes[get_current_buf()] = nil

              return false
            end
          end

          -- No candidate, but have an exit node
          if exit_node then
            -- to jump to the exit node, seek to snippet
            luasnip_lib.session.current_nodes[get_current_buf()] = snippet
            return true
          end

          -- No exit node, exit from snippet
          snippet:remove_from_jumplist()
          luasnip_lib.session.current_nodes[get_current_buf()] = nil
          return false
        end

        if dir == -1 then
          return luasnip_lib.in_snippet() and luasnip_lib.jumpable(-1)
        else
          return luasnip_lib.in_snippet() and seek_luasnip_cursor_node() and luasnip_lib.jumpable(1)
        end
      end

      -- ソース名を事前に定義
      local source_names = {
        nvim_lsp = "(lsp)",
        emoji = "(emoji)",
        path = "(path)",
        calc = "(calc)",
        cmp_tabnine = "(tabnine)",
        vsnip = "(snippet)",
        luasnip = "(snippet)",
        buffer = "(buffer)",
        tmux = "(tmux)",
        copilot = "(copilot)",
        treesitter = "(treesitter)",
      }

      -- 重複設定を事前に定義
      local duplicates = {
        buffer = 1,
        path = 1,
        nvim_lsp = 0,
        luasnip = 1,
      }

      cmp.setup({
        enabled = function()
          local buftype = vim.api.nvim_buf_get_option(0, "buftype")
          if buftype == "prompt" then
            return false
          end
          return true
        end,
        confirm_opts = {
          behavior = cmp.ConfirmBehavior.Replace,
          select = false,
        },
        completion = {
          keyword_length = 1,
        },
        experimental = {
          ghost_text = false,
          native_menu = false,
        },
        formatting = {
          fields = { "kind", "abbr", "menu" },
          max_width = 0,
          kind_icons = icons and icons.kind or {},
          source_names = source_names,
          duplicates = duplicates,
          duplicates_default = 0,
          format = function(entry, vim_item)
            local max_width = 0
            if max_width ~= 0 and #vim_item.abbr > max_width then
              vim_item.abbr = string.sub(vim_item.abbr, 1, max_width - 1) .. "…"
            end
            -- アイコン表示設定
            if icons then
              vim_item.kind = icons.kind[vim_item.kind] or vim_item.kind

              if entry.source.name == "buffer" and icons.misc then
                vim_item.kind = icons.ui.Text
                vim_item.kind_hl_group = "CmpItemKindText"
              end

              if entry.source.name == "copilot" and icons.git then
                vim_item.kind = icons.git.Octoface
                vim_item.kind_hl_group = "CmpItemKindCopilot"
              end

              if entry.source.name == "cmp_tabnine" and icons.misc then
                vim_item.kind = icons.misc.Robot
                vim_item.kind_hl_group = "CmpItemKindTabnine"
              end

              if entry.source.name == "crates" and icons.misc then
                vim_item.kind = icons.misc.Package
                vim_item.kind_hl_group = "CmpItemKindCrate"
              end

              if entry.source.name == "lab.quick_data" and icons.misc then
                vim_item.kind = icons.misc.CircuitBoard
                vim_item.kind_hl_group = "CmpItemKindConstant"
              end

              if entry.source.name == "emoji" and icons.misc then
                vim_item.kind = icons.misc.Smiley
                vim_item.kind_hl_group = "CmpItemKindEmoji"
              end
            end

            -- この行を修正（source_namesはすでに定義されている）
            vim_item.menu = source_names[entry.source.name] or entry.source.name
            -- この行も修正（正しいLuaの構文で書く）
            vim_item.dup = duplicates[entry.source.name] or 0

            return vim_item
          end,
        },
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        window = {
          completion = cmp_window.bordered(),
          documentation = cmp_window.bordered(),
        },
        sources = {
          {
            name = "copilot",
            max_item_count = 3,
            trigger_characters = {
              {
                ".", ":", "(", "'", '"', "[", ",",
                "#", "*", "@", "|", "=", "-", "{",
                "/", "\\", "+", "?", " ",
              },
            },
          },
          {
            name = "nvim_lsp",
            entry_filter = function(entry, ctx)
              local kind = require("cmp.types.lsp").CompletionItemKind[entry:get_kind()]
              if kind == "Snippet" and ctx.prev_context.filetype == "java" then
                return false
              end
              return true
            end,
          },
          { name = "path" },
          { name = "luasnip" },
          { name = "cmp_tabnine" },
          { name = "nvim_lua" },
          { name = "buffer" },
          { name = "calc" },
          { name = "emoji" },
          { name = "treesitter" },
          { name = "crates" },
          { name = "tmux" },
        },
        mapping = cmp_mapping.preset.insert({
          ["<Down>"] = cmp_mapping(cmp_mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }), { "i" }),
          ["<Up>"] = cmp_mapping(cmp_mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }), { "i" }),
          ["<C-y>"] = cmp_mapping({
            i = cmp_mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false }),
            c = function(fallback)
              if cmp.visible() then
                cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
              else
                fallback()
              end
            end,
          }),
          ["<Tab>"] = cmp_mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            elseif jumpable(1) then
              luasnip.jump(1)
            elseif has_words_before() then
              fallback()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp_mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<C-Space>"] = cmp_mapping.complete(),
          ["<C-e>"] = cmp_mapping.abort(),
          ["<CR>"] = cmp_mapping(function(fallback)
            if cmp.visible() then
              local confirm_opts = vim.deepcopy({
                behavior = cmp.ConfirmBehavior.Replace,
                select = false,
              })
              local is_insert_mode = function()
                return vim.api.nvim_get_mode().mode:sub(1, 1) == "i"
              end
              if is_insert_mode() then -- prevent overwriting brackets
                confirm_opts.behavior = cmp.ConfirmBehavior.Insert
              end
              local entry = cmp.get_selected_entry()
              local is_copilot = entry and entry.source.name == "copilot"
              if is_copilot then
                confirm_opts.behavior = cmp.ConfirmBehavior.Replace
                confirm_opts.select = true
              end
              if cmp.confirm(confirm_opts) then
                return -- success, exit early
              end
            end
            fallback() -- if not exited early, always fallback
          end),
        }),
      })

      -- cmdline補完設定
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "path" },
          { name = "cmdline" },
        },
      })

      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })
    end,
  },
}
