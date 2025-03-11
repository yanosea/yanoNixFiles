-- github copilot assistant plugin for avante.nvim
table.insert(lvim.plugins, {
  "yetone/avante.nvim",
  dependencies = {
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "hrsh7th/nvim-cmp",
    "nvim-tree/nvim-web-devicons",
    "zbirenbaum/copilot.lua",
    "MeanderingProgrammer/render-markdown.nvim",
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          use_absolute_path = true,
        },
      },
    },
  },
  event = "VeryLazy",
  lazy = false,
  build = "make",
  version = false,
  init = function()
    local Path = require("plenary.path")
    local avante_path = require("avante.path")
    local cache_path = vim.fn.expand(os.getenv("XDG_CONFIG_HOME") .. "/lvim/lua/user-plugins/utils/ai/avanterules")
    avante_path.prompts.get = function()
      local static_dir = Path:new(cache_path)

      if not static_dir:exists() then
        error("Static directory does not exist: " .. static_dir:absolute(), 2)
      end

      return static_dir:absolute()
    end
  end,
  opts = {
    provider = "copilot",
    copilot = {
      model = "claude-3.7-sonnet",
      disabled_tools = {
        "python",
      },
    },
    -- auto_suggestions_provider = "copilot",
    behaviour = {
      auto_focus_sidebar = false,
      auto_suggestions = true,
      auto_suggestions_respect_ignore = true,
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      support_paste_from_clipboard = true,
      minimize_diff = true,
    },
    windows = {
      position = "right",
      wrap = true,
      width = 30,
      sidebar_header = {
        enabled = true,
        align = "center",
        rounded = false,
      },
      input = {
        prefix = "",
        height = 8,
      },
      edit = {
        border = "rounded",
        start_insert = false,
      },
      ask = {
        floating = false,
        border = "rounded",
        start_insert = false,
      },
    },
  },
})
