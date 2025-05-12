-- lsp config
return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "folke/neodev.nvim",
    },
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      vim.api.nvim_create_user_command("LspInfo", function()
        local clients = vim.lsp.get_clients()
        local bufnr = vim.api.nvim_get_current_buf()
        local ft = vim.bo[bufnr].filetype
        local log_path = vim.lsp.get_log_path()
        local header = {
          " Press q or <Esc> to close this window. Press <Tab> to view server doc.",
          "",
          string.format(" Language client log: %s", log_path),
          string.format(" Detected filetype:   %s", ft),
          "",
        }
        local attached_clients = {}
        local unattached_clients = {}
        for _, client in ipairs(clients) do
          if vim.lsp.buf_is_attached(bufnr, client.id) then
            table.insert(attached_clients, client)
          else
            table.insert(unattached_clients, client)
          end
        end

        local function resolve_full_path(cmd)
          if not cmd or cmd == "" then
            return cmd
          end
          if cmd:sub(1, 1) == "/" then
            return cmd
          end
          local handle = io.popen("which " .. cmd .. " 2>/dev/null")
          if handle then
            local result = handle:read("*a"):gsub("%s+$", "")
            handle:close()
            if result ~= "" then
              return result
            end
          end
          local paths = vim.split(vim.fn.getenv("PATH"), ":")
          for _, path in ipairs(paths) do
            local full_path = path .. "/" .. cmd
            if vim.fn.executable(full_path) == 1 then
              return full_path
            end
          end

          return cmd
        end

        local client_info = {}
        if #attached_clients > 0 then
          table.insert(client_info, string.format(" %d client(s) attached to this buffer: ", #attached_clients))
          table.insert(client_info, "")
          for _, client in ipairs(attached_clients) do
            local buf_list = "["
            for i, buf_id in ipairs(vim.lsp.get_buffers_by_client_id(client.id) or {}) do
              if i > 1 then
                buf_list = buf_list .. ", "
              end
              buf_list = buf_list .. tostring(buf_id)
            end
            buf_list = buf_list .. "]"
            local root_dir = "Running in single file mode."
            if client.config and client.config.root_dir then
              if type(client.config.root_dir) == "function" then
                local status, dir = pcall(client.config.root_dir)
                if status and dir and dir ~= "" then
                  root_dir = dir
                end
              elseif type(client.config.root_dir) == "string" and client.config.root_dir ~= "" then
                root_dir = client.config.root_dir
              end
            end
            local cmd = "Not available"
            if client.config and client.config.cmd then
              if type(client.config.cmd) == "table" and #client.config.cmd > 0 then
                local cmd_args = {}
                local base_cmd = client.config.cmd[1]
                local full_path_cmd = resolve_full_path(base_cmd)
                table.insert(cmd_args, full_path_cmd)
                for i = 2, #client.config.cmd do
                  table.insert(cmd_args, client.config.cmd[i])
                end
                cmd = table.concat(cmd_args, " ")
              elseif type(client.config.cmd) == "function" then
                cmd = "<function>"
              else
                cmd = tostring(client.config.cmd)
              end
            end
            local filetypes = ""
            if client.config and client.config.filetypes then
              if #client.config.filetypes > 0 then
                filetypes = table.concat(client.config.filetypes, ", ")
              else
                filetypes = "*"
              end
            end
            local autostart = "false"
            if client.config and client.config.autostart ~= nil then
              autostart = client.config.autostart and "true" or "false"
            end
            table.insert(
              client_info,
              string.format(" Client: %s (id: %d, bufnr: %s)", client.name, client.id, buf_list)
            )
            table.insert(client_info, string.format(" \tfiletypes:       %s", filetypes))
            table.insert(client_info, string.format(" \tautostart:       %s", autostart))
            table.insert(client_info, string.format(" \troot directory:  %s", root_dir))
            table.insert(client_info, string.format(" \tcmd:             %s", cmd))
            if client.name == "efm" then
              local config_paths = {
                vim.fn.expand("~/.config/efm-langserver/config.yaml"),
                vim.fn.expand("~/.efm-langserver.yaml"),
              }
              local config_path = "Config not found"
              for _, path in ipairs(config_paths) do
                if vim.fn.filereadable(path) == 1 then
                  config_path = path
                  break
                end
              end
              table.insert(client_info, string.format(" \tefm config:      %s", config_path))
              local capabilities = {}
              if client.server_capabilities.documentFormattingProvider then
                table.insert(capabilities, "formatting")
              end
              if client.server_capabilities.codeActionProvider then
                table.insert(capabilities, "code actions")
              end
              if client.server_capabilities.hoverProvider then
                table.insert(capabilities, "hover")
              end
              if client.server_capabilities.documentSymbolProvider then
                table.insert(capabilities, "document symbols")
              end
              if #capabilities > 0 then
                table.insert(client_info, string.format(" \tcapabilities:    %s", table.concat(capabilities, ", ")))
              end
            end
            table.insert(client_info, "")
          end
        else
          table.insert(client_info, " No clients attached to this buffer.")
          table.insert(client_info, "")
        end
        local unattached_info = {}
        if #unattached_clients > 0 then
          table.insert(
            unattached_info,
            string.format(" %d active client(s) not attached to this buffer: ", #unattached_clients)
          )
          table.insert(unattached_info, "")
          for _, client in ipairs(unattached_clients) do
            local buf_list = "["
            for i, buf_id in ipairs(vim.lsp.get_buffers_by_client_id(client.id) or {}) do
              if i > 1 then
                buf_list = buf_list .. ", "
              end
              buf_list = buf_list .. tostring(buf_id)
            end
            buf_list = buf_list .. "]"
            local root_dir = "Running in single file mode."
            if client.config and client.config.root_dir then
              if type(client.config.root_dir) == "function" then
                local status, dir = pcall(client.config.root_dir)
                if status and dir and dir ~= "" then
                  root_dir = dir
                end
              elseif type(client.config.root_dir) == "string" and client.config.root_dir ~= "" then
                root_dir = client.config.root_dir
              end
            end
            local cmd = "Not available"
            if client.config and client.config.cmd then
              if type(client.config.cmd) == "table" and #client.config.cmd > 0 then
                local cmd_args = {}
                local base_cmd = client.config.cmd[1]
                local full_path_cmd = resolve_full_path(base_cmd)
                table.insert(cmd_args, full_path_cmd)
                for i = 2, #client.config.cmd do
                  table.insert(cmd_args, client.config.cmd[i])
                end
                cmd = table.concat(cmd_args, " ")
              elseif type(client.config.cmd) == "function" then
                cmd = "<function>"
              else
                cmd = tostring(client.config.cmd)
              end
            end
            local filetypes = ""
            if client.config and client.config.filetypes then
              if #client.config.filetypes > 0 then
                filetypes = table.concat(client.config.filetypes, ", ")
              else
                filetypes = "*"
              end
            end
            local autostart = "false"
            if client.config and client.config.autostart ~= nil then
              autostart = client.config.autostart and "true" or "false"
            end
            table.insert(
              unattached_info,
              string.format(" Client: %s (id: %d, bufnr: %s)", client.name, client.id, buf_list)
            )
            table.insert(unattached_info, string.format(" \tfiletypes:       %s", filetypes))
            table.insert(unattached_info, string.format(" \tautostart:       %s", autostart))
            table.insert(unattached_info, string.format(" \troot directory:  %s", root_dir))
            table.insert(unattached_info, string.format(" \tcmd:             %s", cmd))
            table.insert(unattached_info, "")
          end
        end
        local other_clients = {}
        local lspconfig = require("lspconfig")
        local all_configs = {}
        local configured_servers = {}
        for server_name, server_obj in pairs(lspconfig) do
          if type(server_obj) == "table" and server_obj.document_config then
            local server_filetypes = server_obj.document_config.default_config.filetypes
            if
              server_filetypes and vim.tbl_contains(server_filetypes, ft)
              or (server_filetypes and #server_filetypes == 0)
              or server_name == "efm"
            then
              table.insert(all_configs, { name = server_name, config = server_obj })
              table.insert(configured_servers, server_name)
            end
          end
        end
        for _, server_config in ipairs(all_configs) do
          local is_attached = false
          for _, client in ipairs(clients) do
            if client.name == server_config.name then
              is_attached = true
              break
            end
          end
          if not is_attached then
            table.insert(other_clients, server_config)
          end
        end
        local other_clients_info = {}
        if #other_clients > 0 then
          table.insert(other_clients_info, string.format(" Other clients that match the filetype: %s", ft))
          table.insert(other_clients_info, "")
          for _, server in ipairs(other_clients) do
            local server_default_config = server.config.document_config.default_config
            local cmd = "Not specified"
            if server_default_config.cmd then
              if type(server_default_config.cmd) == "table" and #server_default_config.cmd > 0 then
                local cmd_args = {}
                local base_cmd = server_default_config.cmd[1]
                local full_path_cmd = resolve_full_path(base_cmd)
                table.insert(cmd_args, full_path_cmd)
                for i = 2, #server_default_config.cmd do
                  table.insert(cmd_args, server_default_config.cmd[i])
                end
                cmd = table.concat(cmd_args, " ")
              elseif type(server_default_config.cmd) == "function" then
                cmd = "<function>"
              else
                cmd = tostring(server_default_config.cmd)
              end
            end
            local filetypes = "*"
            if server_default_config.filetypes and #server_default_config.filetypes > 0 then
              filetypes = table.concat(server_default_config.filetypes, ", ")
            end
            local root_dir = "Not found."
            if server_default_config.root_dir then
              root_dir = "<function>"
            end
            local cmd_executable = "false"
            if type(server_default_config.cmd) == "table" and server_default_config.cmd[1] then
              cmd_executable = vim.fn.executable(server_default_config.cmd[1]) == 1 and "true" or "false"
            end
            local autostart = "true"
            if server_default_config.autostart ~= nil then
              autostart = server_default_config.autostart and "true" or "false"
            end
            table.insert(other_clients_info, string.format(" Config: %s", server.name))
            table.insert(other_clients_info, string.format(" \tfiletypes:         %s", filetypes))
            table.insert(other_clients_info, string.format(" \troot directory:    %s", root_dir))
            table.insert(other_clients_info, string.format(" \tcmd:               %s", cmd))
            table.insert(other_clients_info, string.format(" \tcmd is executable: %s", cmd_executable))
            table.insert(other_clients_info, string.format(" \tautostart:         %s", autostart))
            table.insert(other_clients_info, " \tcustom handlers:   ")
            table.insert(other_clients_info, "")
          end
        end
        local servers_list = {}
        if #configured_servers > 0 then
          table.insert(
            servers_list,
            string.format(" Configured servers list: %s", table.concat(configured_servers, ", "))
          )
          table.insert(servers_list, "")
        end
        local content = {}
        for _, section in ipairs({
          header,
          client_info,
          unattached_info,
          other_clients_info,
          servers_list,
        }) do
          for _, line in ipairs(section) do
            table.insert(content, line)
          end
        end
        local max_line_length = 0
        for _, line in ipairs(content) do
          max_line_length = math.max(max_line_length, #line)
        end
        local width = math.min(vim.o.columns - 4, math.max(80, max_line_length + 4))
        local height = math.min(#content + 2, vim.o.lines - 4)
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
        vim.api.nvim_buf_set_option(buf, "modifiable", false)
        vim.api.nvim_buf_set_option(buf, "filetype", "lspinfo")
        vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
        local win = vim.api.nvim_open_win(buf, true, {
          relative = "editor",
          width = width,
          height = height,
          row = math.floor((vim.o.lines - height) / 2),
          col = math.floor((vim.o.columns - width) / 2),
          style = "minimal",
          border = "single",
        })
        vim.api.nvim_win_set_option(win, "wrap", true)
        vim.api.nvim_win_set_option(win, "cursorline", true)
        local colors = require("utils.colors").colors
        vim.cmd(
          string.format(
            [[
          highlight LspInfoBorder guifg=%s
          highlight LspInfoTitle guifg=%s
          highlight LspInfoHeader guifg=%s gui=bold
          highlight LspInfoFiletype guifg=%s gui=bold
          highlight LspInfoList guifg=%s
          highlight LspInfoClient guifg=%s gui=bold
          highlight LspInfoConfig guifg=%s gui=bold
          highlight LspInfoServerName guifg=%s
          highlight LspInfoTrue guifg=%s
          highlight LspInfoFalse guifg=%s
        ]],
            colors.Blue,
            colors.Yellow,
            colors.Blue,
            colors.Green,
            colors.Fg,
            colors.Blue,
            colors.Purple,
            colors.Aqua,
            colors.Green,
            colors.Red
          )
        )
        vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal,FloatBorder:LspInfoBorder")
        local function add_match(group, pattern)
          pcall(vim.fn.matchadd, group, pattern)
        end
        add_match("LspInfoHeader", "^ Language client log:")
        add_match("LspInfoHeader", "^ Detected filetype:")
        add_match("LspInfoFiletype", " " .. ft .. "$")
        add_match("LspInfoHeader", "^ %d+ client%(s%) attached to this buffer:")
        add_match("LspInfoHeader", "^ %d+ active client%(s%) not attached to this buffer:")
        add_match("LspInfoHeader", "^ Other clients that match the filetype:")
        add_match("LspInfoHeader", "^ Configured servers list:")
        add_match("LspInfoClient", "^ Client: [^ ]\\+")
        add_match("LspInfoConfig", "^ Config: [^ ]\\+")
        add_match("LspInfoList", "^ \\+\\w\\+:\\s\\+")
        add_match("LspInfoTrue", "true")
        add_match("LspInfoFalse", "false")
        add_match("Comment", "^\\s*Press q or")
        vim.api.nvim_buf_set_keymap(buf, "n", "q", ":close<CR>", { noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(buf, "n", "<Esc>", ":close<CR>", { noremap = true, silent = true })
        vim.api.nvim_buf_set_keymap(buf, "n", "<Tab>", "", {
          noremap = true,
          callback = function()
            local line = vim.api.nvim_get_current_line()
            local client_pattern = "^ Client: ([^ ]+)"
            local config_pattern = "^ Config: ([^ ]+)"
            local server_name = line:match(client_pattern) or line:match(config_pattern)
            if server_name then
              local doc_url = "https://github.com/neovim/nvim-lspconfig/blob/master/doc/configs.md#" .. server_name
              vim.fn.system({ "xdg-open", doc_url })
            end
          end,
          desc = "open server documentation",
        })
      end, {})

      local ensure_installed = {
        "efm",
        "gopls",
        "lua_ls",
      }
      require("mason").setup()
      require("mason-lspconfig").setup({
        automatic_installation = true,
        ensure_installed = ensure_installed,
      })
      local colors = require("utils.colors").colors
      local icons = require("utils.icons").icons
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
            [vim.diagnostic.severity.ERROR] = { fg = colors.Red },
            [vim.diagnostic.severity.WARN] = { fg = colors.Yellow },
            [vim.diagnostic.severity.INFO] = { fg = colors.Blue },
            [vim.diagnostic.severity.HINT] = { fg = colors.Green },
          },
        },
        float = {
          source = true,
          border = "single",
          header = "",
          prefix = "",
        },
      })
      require("neodev").setup({
        library = {
          enabled = true,
          runtime = true,
          types = true,
          plugins = true,
        },
        setup_jsonls = true,
        lspconfig = true,
        pathStrict = true,
      })
      local function get_nvim_runtime_dir()
        return vim.fn.expand "$VIMRUNTIME"
      end

      local function get_config_dir()
        return vim.fn.stdpath "config"
      end
      local default_workspace = {
        library = {
          get_nvim_runtime_dir(),
          get_config_dir(),
          require("neodev.config").types(),
          "${3rd}/busted/library",
          "${3rd}/luassert/library",
          "${3rd}/luv/library",
        },
        maxPreload = 5000,
        preloadFileSize = 10000,
      }
      local add_packages_to_workspace = function(packages, config)
        config.settings = config.settings or {}
        config.settings.Lua = config.settings.Lua or {}
        config.settings.Lua.workspace = config.settings.Lua.workspace or {}
        config.settings.Lua.workspace.library = config.settings.Lua.workspace.library or {}
        local ok, runtimedirs = pcall(function()
          return vim.api.nvim__get_runtime({ "lua" }, true, { is_lua = true }) or {}
        end)
        if not ok or type(runtimedirs) ~= "table" then
          runtimedirs = {}
        end
        local workspace_lib = config.settings.Lua.workspace.library
        for _, v in pairs(runtimedirs) do
          for _, pack in ipairs(packages) do
            if v:match(pack) and not vim.tbl_contains(workspace_lib, v) then
              table.insert(workspace_lib, v)
            end
          end
        end
      end

      -- コンフィギュレーションのフック設定
      local lspconfig = require "lspconfig"
      local original_on_new_config = lspconfig.lua_ls.document_config.on_new_config or function() end
      lspconfig.lua_ls.document_config.on_new_config = function(new_config, root_dir)
        original_on_new_config(new_config, root_dir)

        -- プラグインをワークスペースに追加
        local plugins = { "plenary.nvim", "telescope.nvim", "nvim-treesitter", "LuaSnip" }
        add_packages_to_workspace(plugins, new_config)
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
            workspace = default_workspace,
          },
        },
      })

      -- enable popup in :LspInfo
      require("lspconfig.ui.windows").default_options = {
        border = "single",
      }
      vim.lsp.enable(ensure_installed)
    end,
  },

  -- nvim-cmp関連プラグイン
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
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
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

  -- LuaSnipプラグイン
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
  -- Copilotプラグイン
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
  -- Copilot-CMPインテグレーション
  {
    "zbirenbaum/copilot-cmp",
    config = true,
    event = "InsertEnter",
  },
}
