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
  opts = {
    provider = "copilot",
    copilot = {
      model = "claude-3.5-sonnet",
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
