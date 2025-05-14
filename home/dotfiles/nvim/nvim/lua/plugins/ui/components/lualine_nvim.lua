-- status line config
return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    lazy = true,
    event = "VimEnter",
    config = function()
      -- lualine.nvim config
      local colors = require("utils.colors").colors
      local icons = require("utils.icons").icons
      local conditions = {
        hide_in_width = function()
          return vim.fn.winwidth(0) > 80
        end,
      }
      local utils = {
        env_cleanup = function(venv)
          if string.find(venv, "/") then
            local final_venv = venv
            for w in venv:gmatch("([^/]+)") do
              final_venv = w
            end
            venv = final_venv
          end
          return venv
        end,
      }
      local function diff_source()
        local gitsigns = vim.b.gitsigns_status_dict
        if gitsigns then
          return {
            added = gitsigns.added,
            modified = gitsigns.changed,
            removed = gitsigns.removed,
          }
        end
      end
      local components = {
        mode = {
          function()
            return " " .. icons.ui.Target .. " "
          end,
          padding = { left = 0, right = 0 },
          color = {},
          cond = nil,
        },
        branch = {
          "b:gitsigns_head",
          icon = icons.git.Branch,
          color = { gui = "bold" },
        },
        filename = {
          "filename",
          color = {},
          cond = nil,
        },
        diff = {
          "diff",
          source = diff_source,
          symbols = {
            added = icons.git.LineAdded .. " ",
            modified = icons.git.LineModified .. " ",
            removed = icons.git.LineRemoved .. " ",
          },
          padding = { left = 2, right = 1 },
          diff_color = {
            added = { fg = colors.Green },
            modified = { fg = colors.Yellow },
            removed = { fg = colors.Red },
          },
          cond = nil,
        },
        python_env = {
          function()
            if vim.bo.filetype == "python" then
              local venv = os.getenv("CONDA_DEFAULT_ENV") or os.getenv("VIRTUAL_ENV")
              if venv then
                local devicons = require("nvim-web-devicons")
                local py_icon, _ = devicons.get_icon(".py")
                return string.format(" " .. py_icon .. " (%s)", utils.env_cleanup(venv))
              end
            end
            return ""
          end,
          color = { fg = colors.Green },
          cond = conditions.hide_in_width,
        },
        diagnostics = {
          "diagnostics",
          sources = { "nvim_diagnostic" },
          symbols = {
            error = icons.diagnostics.BoldError .. " ",
            warn = icons.diagnostics.BoldWarning .. " ",
            info = icons.diagnostics.BoldInformation .. " ",
            hint = icons.diagnostics.BoldHint .. " ",
          },
        },
        treesitter = {
          function()
            return icons.ui.Tree
          end,
          color = function()
            local buf = vim.api.nvim_get_current_buf()
            local ts = vim.treesitter.highlighter.active[buf]
            return { fg = ts and not vim.tbl_isempty(ts) and colors.Green or colors.Red }
          end,
          cond = conditions.hide_in_width,
        },
        lsp = {
          function()
            local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
            if #buf_clients == 0 then
              return "lsp inactive"
            end
            local buf_client_names = {}
            local copilot_active = false
            local efm_active = false
            local efm_tools = {}
            for _, client in pairs(buf_clients) do
              -- if copilot is active, set color
              if client.name == "copilot" then
                copilot_active = true
                goto continue
              end
              -- if efm is active, get tools
              if client.name == "efm" then
                efm_active = true
                local ft = vim.bo.filetype
                if client.config and client.config.settings and client.config.settings.languages then
                  local ft_tools = client.config.settings.languages[ft]
                  if ft_tools then
                    for _, tool in ipairs(ft_tools) do
                      local raw_command = tool.prefix or tool.lintCommand or tool.formatCommand or ""
                      local tool_name = ""
                      if raw_command ~= "" then
                        local normalized_cmd = string.gsub(raw_command, "//", "/")
                        local cmd_parts = {}
                        for part in string.gmatch(normalized_cmd, "%S+") do
                          table.insert(cmd_parts, part)
                        end
                        if #cmd_parts > 0 then
                          local path = cmd_parts[1]
                          tool_name = string.match(path, "([^/\\]+)$") or ""
                        end
                      end
                      if tool_name ~= "" then
                        table.insert(efm_tools, tool_name)
                      end
                    end
                  end
                end
              end
              table.insert(buf_client_names, client.name)
              ::continue::
            end
            -- remove duplicates
            local unique_client_names = table.concat(buf_client_names, ", ")
            local language_servers = string.format("[%s]", unique_client_names)
            -- efm tools
            if efm_active then
              local client_names_new = {}
              for _, name in ipairs(buf_client_names) do
                if name == "efm" then
                  if #efm_tools > 0 then
                    local unique_tools = {}
                    for _, v in ipairs(efm_tools) do
                      unique_tools[v] = true
                    end
                    local tool_list = {}
                    for tool, _ in pairs(unique_tools) do
                      table.insert(tool_list, tool)
                    end
                    local tool_info = "efm(" .. table.concat(tool_list, ", ") .. ")"
                    table.insert(client_names_new, tool_info)
                  end
                else
                  table.insert(client_names_new, name)
                end
              end
              buf_client_names = client_names_new
              unique_client_names = table.concat(buf_client_names, ", ")
              language_servers = string.format("[%s]", unique_client_names)
            end
            -- copilot icon
            if copilot_active then
              vim.api.nvim_set_hl(0, "LualineCopilot", { fg = colors.Green })
              language_servers = language_servers .. " %#LualineCopilot#" .. icons.git.Octoface .. " " .. "%*"
            end
            -- return copilot icon if active
            if language_servers == "[]" and not copilot_active then
              return "#{LualineCopilot}" .. icons.git.Octoface .. " " .. "%*"
            end
            -- return empty string if no lsp clients
            if language_servers == "[]" then
              return ""
            end
            return language_servers
          end,
          color = { gui = "bold" },
          cond = conditions.hide_in_width,
        },
        location = { "location" },
        progress = {
          "progress",
          fmt = function()
            return "%P/%L"
          end,
          color = {},
        },
        spaces = {
          function()
            local shiftwidth = vim.api.nvim_get_option_value("shiftwidth", { buf = 0 })
            return icons.ui.Tab .. " " .. shiftwidth
          end,
          padding = 1,
        },
        encoding = {
          "o:encoding",
          fmt = string.upper,
          color = {},
          cond = conditions.hide_in_width,
        },
        filetype = { "filetype", cond = nil, padding = { left = 1, right = 1 } },
        scrollbar = {
          function()
            local current_line = vim.fn.line(".")
            local total_lines = vim.fn.line("$")
            local chars = {
              icons.scrollbars.Min,
              icons.scrollbars.Bar1,
              icons.scrollbars.Bar2,
              icons.scrollbars.Bar3,
              icons.scrollbars.Bar4,
              icons.scrollbars.Bar5,
              icons.scrollbars.Bar6,
              icons.scrollbars.Bar7,
              icons.scrollbars.Max,
            }
            local line_ratio = current_line / total_lines
            local index = math.ceil(line_ratio * #chars)
            return chars[index]
          end,
          padding = { left = 0, right = 0 },
          color = "SLProgress",
          cond = nil,
        },
      }
      if #vim.api.nvim_list_uis() == 0 then
        print("headless mode detected, skipping lualine setup")
        return
      end
      local lualine_config = {
        options = {
          theme = vim.g.colors_name or "auto",
          globalstatus = true,
          icons_enabled = true,
          component_separators = {
            left = icons.ui.DividerRight,
            right = icons.ui.DividerLeft,
          },
          section_separators = {
            left = icons.ui.BoldDividerRight,
            right = icons.ui.BoldDividerLeft,
          },
          disabled_filetypes = { "alpha" },
        },
        sections = {
          lualine_a = {
            components.mode,
          },
          lualine_b = {
            components.branch,
          },
          lualine_c = {
            components.diff,
            components.python_env,
          },
          lualine_x = {
            components.diagnostics,
            components.lsp,
            components.spaces,
            components.filetype,
          },
          lualine_y = { components.location },
          lualine_z = {
            components.progress,
          },
        },
        inactive_sections = {
          lualine_a = {
            components.mode,
          },
          lualine_b = {
            components.branch,
          },
          lualine_c = {
            components.diff,
            components.python_env,
          },
          lualine_x = {
            components.diagnostics,
            components.lsp,
            components.spaces,
            components.filetype,
          },
          lualine_y = { components.location },
          lualine_z = {
            components.progress,
          },
        },
        tabline = {},
        extensions = {},
      }
      require("lualine").setup(lualine_config)
    end,
  },
}
