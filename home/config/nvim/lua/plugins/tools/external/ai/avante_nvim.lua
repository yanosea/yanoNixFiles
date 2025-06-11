-- github copilot assistant plugin for avante.nvim
-- keymaps are set in lua/pulugins/tools/internal/which_key_nvim.lua (<LEADER>aa)
return {
	{
		"yetone/avante.nvim",
		version = false,
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
		lazy = true,
		cmd = {
			"AvanteAsk",
			"AvanteClear",
			"AvanteEdit",
			"AvanteFocus",
			"AvanteRefresh",
			"AvanteRepoMap",
			"AvanteStop",
			"AvanteToggle",
		},
		build = "make",
		opts = {
			provider = "copilot",
			mode = "agentic",
			auto_suggestions_provider = "copilot",
			memory_summary_provider = "copilot",
			tokenizer = "tiktoken",
			system_prompt = require("plugins.tools.external.ai.prompts.system_prompt").prompt,
			rag_service = { -- RAG service configuration
				enabled = false, -- Enables the RAG service
				host_mount = os.getenv("HOME"), -- Host mount path for the RAG service (Docker will mount this path)
				runner = "docker", -- The runner for the RAG service (can use docker or nix)
				llm = { -- Configuration for the Language Model (LLM) used by the RAG service
					provider = "openai", -- The LLM provider
					endpoint = "https://api.openai.com/v1", -- The LLM API endpoint
					api_key = "OPENAI_API_KEY", -- The environment variable name for the LLM API key
					model = "gpt-4o-mini", -- The LLM model name
					extra = nil, -- Extra configuration options for the LLM
				},
				embed = { -- Configuration for the Embedding model used by the RAG service
					provider = "openai", -- The embedding provider
					endpoint = "https://api.openai.com/v1", -- The embedding API endpoint
					api_key = "OPENAI_API_KEY", -- The environment variable name for the embedding API key
					model = "text-embedding-3-large", -- The embedding model name
					extra = nil, -- Extra configuration options for the embedding model
				},
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
			providers = {
				copilot = {
					endpoint = "https://api.githubcopilot.com",
					model = "claude-3.7-sonnet",
					proxy = nil, -- [protocol://]host[:port] Use this proxy
					allow_insecure = true, -- Allow insecure server connections
					timeout = 60000, -- Timeout in milliseconds
					extra_request_body = {
						temperature = 0.75, -- Temperature for the model
						max_tokens = 20480, -- Max tokens for the model
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
				auto_suggestions = false,
				auto_suggestions_respect_ignore = false,
				auto_set_highlight_group = true,
				auto_set_keymaps = true,
				auto_apply_diff_after_generation = false,
				jump_result_buffer_on_finish = true,
				support_paste_from_clipboard = true,
				minimize_diff = true,
				enable_token_counting = true,
				use_cwd_as_project_root = true,
				auto_focus_on_diff_view = false,
				auto_approve_tool_permissions = true,
				auto_check_diagnostics = true,
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
			mappings = {
				diff = {
					ours = "co",
					theirs = "ct",
					all_theirs = "ca",
					both = "cb",
					cursor = "cc",
					next = "]x",
					prev = "[x",
				},
				suggestion = {
					accept = "<M-l>",
					next = "<M-]>",
					prev = "<M-[>",
					dismiss = "<C-]>",
				},
				jump = {
					next = "]]",
					prev = "[[",
				},
				submit = {
					normal = "<CR>",
					insert = "<C-s>",
				},
				cancel = {
					normal = { "<C-c>", "<Esc>", "q" },
					insert = { "<C-c>" },
				},
				ask = "<LEADER>aaa",
				new_ask = "<LEADER>aan",
				edit = "<LEADER>aae",
				refresh = "<LEADER>aar",
				focus = "<LEADER>aaf",
				stop = "<LEADER>aas",
				toggle = {
					default = "<LEADER>aat",
					debug = "<LEADER>aad",
					hint = "<LEADER>aah",
					suggestion = "<LEADER>aas",
					repomap = "<LEADER>aaR",
				},
				sidebar = {
					apply_all = "A",
					apply_cursor = "a",
					retry_user_request = "r",
					edit_user_request = "e",
					switch_windows = "<Tab>",
					reverse_switch_windows = "<S-Tab>",
					remove_file = "d",
					add_file = "@",
					close = { "q" },
					close_from_input = nil, -- e.g., { normal = "<Esc>", insert = "<C-d>" }
				},
				files = {
					add_current = "<leader>aac", -- Add current buffer to selected files
					add_all_buffers = "<leader>aaB", -- Add all buffer files to selected files
				},
				select_model = "<leader>aa?", -- Select model command
				select_history = "<leader>aaH", -- Select history command
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
				-- options override for custom providers
				provider_opts = {},
			},
			selector = {
				provider = "fzf_lua",
				provider_opts = {},
				exclude_auto_select = {}, -- List of items to exclude from auto selection
			},
			input = {
				provider = "native",
				provider_opts = {},
			},
			suggestion = {
				debounce = 600,
				throttle = 600,
			},
			disabled_tools = {
				"python",
			},
			custom_tools = {},
			slash_commands = {},
		},
	},
}
