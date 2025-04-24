-- github copilot assistant plugin for avante.nvim
table.insert(lvim.plugins, {
  "yetone/avante.nvim",
  event = "VeryLazy",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    { "echasnovski/mini.pick", lazy = true }, -- for file_selector provider mini.pick
    { "nvim-telescope/telescope.nvim", lazy = true }, -- for file_selector provider telescope
    { "hrsh7th/nvim-cmp", lazy = true }, -- autocompletion for avante commands and mentions
    { "ibhagwan/fzf-lua", lazy = true }, -- for file_selector provider fzf
    { "nvim-tree/nvim-web-devicons", lazy = true }, -- or echasnovski/mini.icons
    { "zbirenbaum/copilot.lua", lazy = true }, -- for providers='copilot'
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      lazy = true,
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          -- required for Windows users
          use_absolute_path = true,
        },
      },
    },
  },
  build = "make",
  version = false,
  opts = {
    provider = "copilot",
    auto_suggestions_provider = "copilot",
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
      enable_token_counting = true,
      enable_cursor_planning_mode = false,
      enable_claude_text_editor_tool_mode = false,
    },
    hints = { enabled = true },
    windows = {
      position = "right",
      wrap = true,
      width = 32,
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
        border = "single",
        start_insert = false,
      },
      ask = {
        floating = false,
        border = "single",
        start_insert = false,
        focus_on_apply = "ours",
      },
    },
    web_search_engine = {
      provider = "tavily", -- tavily, serpapi, searchapi, google, kagi, brave, or searxng
      proxy = nil, -- proxy support, e.g., http://127.0.0.1:7890
    },
  },
  init = function()
    local Path = require("plenary.path")
    local avante_path = require("avante.path")
    local config_home = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
    local cache_path = config_home .. "/lvim/lua/user/tool/external/ai/avanterules"
    -- override the get_templates_dir function to use our custom path
    avante_path.prompts.get_templates_dir = function()
      -- ignore the project_root parameter and return our custom path
      local static_dir = Path:new(cache_path)

      if not static_dir:exists() then
        error("Static directory does not exist: " .. static_dir:absolute(), 2)
      end

      return static_dir:absolute()
    end
  end,
})
