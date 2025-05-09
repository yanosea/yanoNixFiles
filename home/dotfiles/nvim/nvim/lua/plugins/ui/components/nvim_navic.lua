-- comment utilizes the same keybinding as the default comment plugin
return {
  {
    "SmiteshP/nvim-navic",
    dependencies = {
      "nvim-web-devicons",
    },
    lazy = true,
    event = "BufRead",
    opts = {
      icons = {
        Array = "",
        Boolean = "",
        Class = "",
        Color = "",
        Constant = "",
        Constructor = "",
        Enum = "",
        EnumMember = "",
        Event = "",
        Field = "",
        File = "",
        Folder = "󰉋",
        Function = "",
        Interface = "",
        Key = "",
        Keyword = "",
        Method = "",
        Module = "",
        Namespace = "",
        Null = "󰟢",
        Number = "",
        Object = "",
        Operator = "",
        Package = "",
        Property = "",
        Reference = "",
        Snippet = "",
        String = "",
        Struct = "",
        Text = "",
        TypeParameter = "",
        Unit = "",
        Value = "",
        Variable = "",
      },
      highlight = true,
      separator = " ",
      depth_limit = 0,
      depth_limit_indicator = "..",
    },
    config = function(_, opts)
      local navic = require("nvim-navic")
      navic.setup(opts)
      local excluded_filetypes = {
        "help",
        "startify",
        "dashboard",
        "lazy",
        "neo-tree",
        "neogitstatus",
        "NvimTree",
        "Trouble",
        "alpha",
        "lir",
        "Outline",
        "spectre_panel",
        "toggleterm",
        "DressingSelect",
        "Jaq",
        "harpoon",
        "dap-repl",
        "dap-terminal",
        "dapui_console",
        "dapui_hover",
        "lab",
        "notify",
        "noice",
        "neotest-summary",
        "",
      }

      local function get_filename()
        local filename = vim.fn.expand("%:t")
        local extension = vim.fn.expand("%:e")

        if filename ~= "" then
          local file_icon, hl_group
          local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
          if devicons_ok then
            file_icon, hl_group = devicons.get_icon(filename, extension, { default = true })

            if not file_icon or file_icon == "" then
              file_icon = ""
            end
          else
            file_icon = ""
            hl_group = "Normal"
          end

          local buf_ft = vim.bo.filetype

          if buf_ft == "dapui_breakpoints" then
            file_icon = ""
          elseif buf_ft == "dapui_stacks" then
            file_icon = ""
          elseif buf_ft == "dapui_scopes" then
            file_icon = ""
          elseif buf_ft == "dapui_watches" then
            file_icon = "󰂥"
          end

          local navic_text = vim.api.nvim_get_hl_by_name("Normal", true)
          vim.api.nvim_set_hl(0, "Winbar", { fg = navic_text.foreground })

          return " " .. "%#" .. hl_group .. "#" .. file_icon .. "%*" .. " " .. "%#Winbar#" .. filename .. "%*"
        end
        return ""
      end

      local function get_gps()
        local gps_location = navic.get_location()

        if gps_location ~= "" and navic.is_available() then
          return "%#NavicSeparator#" .. "󰄾" .. "%* " .. gps_location
        end
        return ""
      end

      local function get_winbar()
        if vim.tbl_contains(excluded_filetypes, vim.bo.filetype) then
          return
        end

        local value = get_filename()
        local gps_added = false

        if value ~= "" then
          local gps_value = get_gps()
          value = value .. " " .. gps_value
          if gps_value ~= "" then
            gps_added = true
          end
        end

        if value ~= "" and vim.bo.modified then
          local mod = "%#LspCodeLens#" .. "●" .. "%*"
          if gps_added then
            value = value .. " " .. mod
          else
            value = value .. mod
          end
        end

        local num_tabs = #vim.api.nvim_list_tabpages()
        if num_tabs > 1 and value ~= "" then
          local tabpage_number = tostring(vim.api.nvim_tabpage_get_number(0))
          value = value .. "%=" .. tabpage_number .. "/" .. tostring(num_tabs)
        end

        pcall(vim.api.nvim_set_option_value, "winbar", value, { scope = "local" })
      end

      local augroup = vim.api.nvim_create_augroup("NavicWinbar", {})
      vim.api.nvim_create_autocmd({
        "CursorHoldI",
        "CursorHold",
        "BufWinEnter",
        "BufFilePost",
        "InsertEnter",
        "BufWritePost",
        "TabClosed",
        "TabEnter",
      }, {
        group = augroup,
        callback = function()
          local status_ok, _ = pcall(vim.api.nvim_buf_get_var, 0, "lsp_floating_window")
          if not status_ok then
            get_winbar()
          end
        end,
      })
    end,
  },
}
