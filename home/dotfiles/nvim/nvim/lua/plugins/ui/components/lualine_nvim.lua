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
              return "LSP Inactive"
            end
            local buf_client_names = {}
            local copilot_active = false
            for _, client in pairs(buf_clients) do
              if client.name == "GitHub Copilot" then
                copilot_active = true
                goto continue
              end

              if client.name ~= "null-ls" and client.name ~= "copilot" then
                table.insert(buf_client_names, client.name)
              end

              ::continue::
            end
            local unique_client_names = table.concat(buf_client_names, ", ")
            local language_servers = string.format("[%s]", unique_client_names)
            if copilot_active then
              vim.api.nvim_set_hl(0, "LualineCopilot", { fg = colors.Green })
              language_servers = language_servers .. " %#LualineCopilot#" .. icons.git.Octoface .. " " .. "%*"
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
            local shiftwidth = vim.api.nvim_buf_get_option(0, "shiftwidth")
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
