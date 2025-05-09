-- status line config
return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    lazy = true,
    event = "UIEnter",
    config = function()
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
        ui = {
          Target = "󰀘",
          Tree = "",
          Tab = "",
          BoldDividerRight = "",
          BoldDividerLeft = "",
          DividerRight = "",
          DividerLeft = "",
        },
        git = {
          Branch = "",
          LineAdded = "",
          LineModified = "",
          LineRemoved = "",
          Octoface = "",
        },
        diagnostics = {
          BoldError = "",
          BoldWarning = "",
          BoldInformation = "",
          BoldHint = "",
        },
      }
      local conditions = {
        hide_in_width = function()
          return vim.fn.winwidth(0) > 80
        end,
      }
      local utils = {
        env_cleanup = function(venv)
          if string.find(venv, "/") then
            local final_venv = venv
            for w in venv:gmatch "([^/]+)" do
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
            added = { fg = colors.green },
            modified = { fg = colors.yellow },
            removed = { fg = colors.red },
          },
          cond = nil,
        },
        python_env = {
          function()
            if vim.bo.filetype == "python" then
              local venv = os.getenv "CONDA_DEFAULT_ENV" or os.getenv "VIRTUAL_ENV"
              if venv then
                local icons = require "nvim-web-devicons"
                local py_icon, _ = icons.get_icon ".py"
                return string.format(" " .. py_icon .. " (%s)", utils.env_cleanup(venv))
              end
            end
            return ""
          end,
          color = { fg = colors.green },
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
            return { fg = ts and not vim.tbl_isempty(ts) and colors.green or colors.red }
          end,
          cond = conditions.hide_in_width,
        },
        lsp = {
          function()
            local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
            if #buf_clients == 0 then
              return "LSP Inactive"
            end
            local buf_ft = vim.bo.filetype
            local buf_client_names = {}
            local copilot_active = false
            for _, client in pairs(buf_clients) do
              if client.name ~= "null-ls" and client.name ~= "copilot" then
                table.insert(buf_client_names, client.name)
              end

              if client.name == "copilot" then
                copilot_active = true
              end
            end
            local unique_client_names = table.concat(buf_client_names, ", ")
            local language_servers = string.format("[%s]", unique_client_names)
            if copilot_active then
              language_servers = language_servers .. " " .. icons.git.Octoface
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
            local current_line = vim.fn.line "."
            local total_lines = vim.fn.line "$"
            local chars = { "__", "▁▁", "▂▂", "▃▃", "▄▄", "▅▅", "▆▆", "▇▇", "██" }
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
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
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
