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
	-- web
	"astro",
	"cssls",
	"html",
	"jsonls",
	-- markdown
	"marksman",
	-- lua
	"lua_ls",
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
	-- typescript
	"denols",
	"ts_ls",
	-- toml
	"taplo",
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
