-- github copilot assistant plugin for avante.nvim
table.insert(lvim.plugins, {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  build = "make",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    --- The below dependencies are optional,
    { "nvim-telescope/telescope.nvim", lazy = true }, -- for file_selector provider telescope
    { "hrsh7th/nvim-cmp", lazy = true }, -- autocompletion for avante commands and mentions
    { "ibhagwan/fzf-lua", lazy = true }, -- for file_selector provider fzf
    { "nvim-tree/nvim-web-devicons", lazy = true }, -- or echasnovski/mini.icons
    { "zbirenbaum/copilot.lua", lazy = true }, -- for providers='copilot'
  },
  opts = {
    provider = "copilot",
    mode = "agentic",
    -- mode = "legacy",
    auto_suggestions_provider = "copilot",
    cursor_applying_provider = "copilot",
    memory_summary_provider = "copilot",
    copilot = {
      endpoint = "https://api.githubcopilot.com",
      model = "claude-3.7-sonnet",
      proxy = nil, -- [protocol://]host[:port] Use this proxy
      allow_insecure = true, -- Allow insecure server connections
      timeout = 60000, -- Timeout in milliseconds
      temperature = 0,
      max_tokens = 50960,
    },
    system_prompt = require("plugins.user.tools.external.ai.system_prompt").SystemPrompt,
    rag_service = {
      enabled = false, -- Enables the rag service, requires OPENAI_API_KEY to be set
      host_mount = os.getenv("HOME"), -- Host mount path for the rag service (docker will mount this path)
      runner = "docker", -- The runner for the rag service, (can use docker, or nix)
      provider = "openai", -- The provider to use for RAG service. eg: openai or ollama
      llm_model = "", -- The LLM model to use for RAG service
      embed_model = "", -- The embedding model to use for RAG service
      endpoint = "https://api.openai.com/v1", -- The API endpoint for RAG service
      docker_extra_args = "", -- Extra arguments to pass to the docker command
    },
    web_search_engine = {
      provider = "tavily",
      proxy = nil,
      providers = {
        tavily = {
          api_key_name = "TAVILY_API_KEY",
          extra_request_body = {
            include_answer = "basic",
          },
          format_response_body = function(body)
            return body.answer, nil
          end,
        },
      },
    },
    dual_boost = {
      enabled = false,
      first_provider = "copilot",
      second_provider = "copilot",
      prompt = "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
      timeout = 60000, -- Timeout in milliseconds
    },
    behaviour = {
      auto_focus_sidebar = false,
      auto_suggestions = true,
      auto_suggestions_respect_ignore = true,
      auto_set_highlight_group = true,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
      jump_result_buffer_on_finish = true,
      support_paste_from_clipboard = true,
      minimize_diff = true,
      enable_token_counting = true,
      use_cwd_as_project_root = true,
      auto_focus_on_diff_view = false,
    },
    history = {
      max_tokens = 20480,
      carried_entry_count = nil,
      storage_path = vim.fn.stdpath("state") .. "/avante",
      paste = {
        extension = "png",
        filename = "pasted-%Y-%m-%d-%H-%M-%S",
      },
    },
    highlights = {
      diff = {
        current = nil,
        incoming = nil,
      },
    },
    img_paste = {
      url_encode_path = true,
      template = "\nimage: $FILE_PATH\n",
    },
    windows = {
      position = "right",
      fillchars = "eob: ",
      wrap = true,
      width = 32,
      height = 32,
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
    diff = {
      autojump = false,
      override_timeoutlen = 500,
    },
    hints = {
      enabled = true,
    },
    repo_map = {
      ignore_patterns = { "%.git", "%.worktree", "__pycache__", "node_modules" }, -- ignore files matching these
      negate_patterns = {}, -- negate ignore files matching these.
    },
    file_selector = {
      provider = nil,
      -- Options override for custom providers
      provider_opts = {},
    },
    selector = {
      provider = "telescope",
      provider_opts = {},
      exclude_auto_select = {}, -- List of items to exclude from auto selection
    },
    suggestion = {
      debounce = 600,
      throttle = 600,
    },
    disabled_tools = {},
    custom_tools = {},
    slash_commands = {},
  },
})
