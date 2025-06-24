-- efm lsp config
local M = {}
function M.setup()
	vim.lsp.config("efm", {
		init_options = {
			documentFormatting = true,
			documentRangeFormatting = true,
		},
		settings = {
			root_markers = {
				-- common
				".git",
				-- go
				"go.mod",
				"go.sum",
				".golangci.yml",
				".golangci.yaml",
				-- lua
				".luacheckrc",
				".luarc.json",
				".stylua.toml",
				"stylua.toml",
				-- nix
				"flake.nix",
				"default.nix",
				-- shell
				".shellcheckrc",
				-- web
				".prettier.config.js",
				".prettierrc",
				".prettierrc.js",
				".prettierrc.json",
				".prettierrc.yml",
				"prettier.config.js",
				"package.json",
				"tsconfig.json",
			},
			languages = {
				-- common
				["_"] = {
					require("efmls-configs.linters.proselint"),
				},
				-- docker
				dockerfile = {
					require("efmls-configs.linters.hadolint"),
				},
				-- go
				go = {
					require("efmls-configs.formatters.goimports"),
					require("efmls-configs.linters.golangci_lint"),
				},
				-- lua
				lua = {
					require("efmls-configs.formatters.stylua"),
				},
				-- make
				make = {
					require("efmls-configs.linters.checkmake"),
				},
				-- nix
				nix = {
					require("efmls-configs.formatters.nixfmt"),
				},
				-- rust
				rust = {
					require("efmls-configs.formatters.rustfmt"),
				},
				-- shell
				sh = {
					require("efmls-configs.formatters.shfmt"),
					require("efmls-configs.linters.shellcheck"),
				},
				bash = {
					require("efmls-configs.formatters.shfmt"),
					require("efmls-configs.linters.shellcheck"),
				},
				zsh = {
					require("efmls-configs.formatters.shfmt"),
					require("efmls-configs.linters.shellcheck"),
				},
				-- sql
				sql = {
					require("efmls-configs.formatters.sql-formatter"),
				},
				-- web
				javascript = {
					require("efmls-configs.formatters.prettier"),
				},
				typescript = {
					require("efmls-configs.formatters.prettier"),
				},
				javascriptreact = {
					require("efmls-configs.formatters.prettier"),
				},
				typescriptreact = {
					require("efmls-configs.formatters.prettier"),
				},
				vue = {
					require("efmls-configs.formatters.prettier"),
				},
				css = {
					require("efmls-configs.formatters.prettier"),
				},
				html = {
					require("efmls-configs.formatters.prettier"),
				},
				json = {
					require("efmls-configs.formatters.prettier"),
				},
				yaml = {
					require("efmls-configs.formatters.prettier"),
				},
				markdown = {
					require("efmls-configs.formatters.prettier"),
					require("efmls-configs.linters.proselint"),
				},
				astro = {
					require("efmls-configs.formatters.prettier"),
				},
				svelte = {
					require("efmls-configs.formatters.prettier"),
				},
			},
		},
	})
end
return M
