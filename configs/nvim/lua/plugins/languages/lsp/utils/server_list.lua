-- lsp server list
local M = {}
-- lsp servers
M.servers = {
	-- common
	"ast_grep",
	"efm",
	"diagnosticls",
	"typos_lsp",
	-- docker
	"docker_compose_language_service",
	"dockerls",
	-- go
	"golangci_lint_ls",
	"gopls",
	-- lua
	"lua_ls",
	-- markdown
	"markdown_oxide",
	-- nix
	"nil_ls",
	-- rust
	"rust_analyzer",
	-- shell
	"bashls",
	-- sql
	"sqlls",
	-- tailwind
	"tailwindcss",
	-- toml
	"taplo",
	-- typescript
	"denols",
	"ts_ls",
	-- web
	"astro",
	"cssls",
	"html",
	"jsonls",
	-- yaml
	"yamlls",
}
-- tools
M.tools = {
	-- common
	"proselint",
	-- docker
	"hadolint",
	-- go
	"delve",
	"goimports",
	"golangci-lint",
	-- kdl
	"kdlfmt",
	-- lua
	"stylua",
	-- make
	"checkmake",
	-- nix
	"nixpkgs-fmt",
	-- rustfmt
	"rustfmt",
	-- shell
	"shfmt",
	"shellcheck",
	-- sql
	"sql-formatter",
	-- web
	"prettier",
}
return M
