-- completion config
return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "chrisgrieser/cmp-nerdfont",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-calc",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-emoji",
      "hrsh7th/cmp-path",
      "ray-x/cmp-treesitter",
      "saadparwaiz1/cmp_luasnip",
      "zbirenbaum/copilot-cmp",
    },
    lazy = true,
    event = { "InsertEnter", "CmdlineEnter" },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local cmp_window = require("cmp.config.window")
      local cmp_mapping = require("cmp.config.mapping")
      local icons = require("utils.icons").icons
      -- define has_words_before function
      local has_words_before = function()
        local line, col = table.unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
      end
      -- define jumpable function
      local function jumpable(dir)
        local luasnip_status, luasnip_lib = pcall(require, "luasnip")
        if not luasnip_status then
          return false
        end
        local win_get_cursor = vim.api.nvim_win_get_cursor
        local get_current_buf = vim.api.nvim_get_current_buf
        -- define function to seek luasnip cursor node
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
            -- past unmarked exit node, exit early
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
          -- no candidate, but have an exit node
          if exit_node then
            -- to jump to the exit node, seek to snippet
            luasnip_lib.session.current_nodes[get_current_buf()] = snippet
            return true
          end
          -- no exit node, exit from snippet
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
      -- define sources
      local source_names = {
        buffer = "(buffer)",
        calc = "(calc)",
        copilot = "(copilot)",
        emoji = "(emoji)",
        luasnip = "(snippet)",
        nerdfont = "(nerdfont)",
        nvim_lsp = "(lsp)",
        path = "(path)",
        treesitter = "(treesitter)",
      }
      -- define duplicates
      local duplicates = {
        buffer = 1,
        path = 1,
        nvim_lsp = 0,
        luasnip = 1,
      }
      cmp.setup({
        enabled = function()
          local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })
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
            local colors = require("utils.colors").colors
            local max_width = 0
            if max_width ~= 0 and #vim_item.abbr > max_width then
              vim_item.abbr = string.sub(vim_item.abbr, 1, max_width - 1) .. "…"
            end
            -- set icons
            if icons then
              vim_item.kind = icons.kind[vim_item.kind] or vim_item.kind
              if entry.source.name == "buffer" and icons.misc then
                vim_item.kind = icons.ui.Text
                vim_item.kind_hl_group = "CmpItemKindText"
              end
              if entry.source.name == "copilot" and icons.git then
                vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = colors.Green })
                vim_item.kind = icons.git.Octoface
                vim_item.kind_hl_group = "CmpItemKindCopilot"
              end
              if entry.source.name == "emoji" and icons.misc then
                vim_item.kind = icons.misc.Smiley
                vim_item.kind_hl_group = "CmpItemKindEmoji"
              end
            end
            vim_item.menu = source_names[entry.source.name] or entry.source.name
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
          { name = "buffer" },
          { name = "calc" },
          {
            name = "copilot",
            max_item_count = 3,
            trigger_characters = {
              {
                ".",
                ":",
                "(",
                "'",
                '"',
                "[",
                ",",
                "#",
                "*",
                "@",
                "|",
                "=",
                "-",
                "{",
                "/",
                "\\",
                "+",
                "?",
                " ",
              },
            },
          },
          { name = "emoji" },
          { name = "luasnip" },
          { name = "nerdfont" },
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
          { name = "treesitter" },
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
                -- success, exit early
                return
              end
            end
            -- if not exited early, always fallback
            fallback()
          end),
        }),
      })
      -- command line setup
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "cmdline" },
          { name = "path" },
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
