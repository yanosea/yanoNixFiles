-- syntax highlighting and code folding
return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		config = function()
			-- nvim-treesitter config
			require("nvim-treesitter.configs").setup({
				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},
				incremental_selection = {
					enable = true,
				},
				indent = {
					enable = true,
				},
				ensure_installed = {
					-- common
					"comment",
					"diff",
					"git_config",
					"git_rebase",
					"gitattributes",
					"gitcommit",
					"gitignore",
					"ini",
					"regex",
					-- astro
					"astro",
					-- bash
					"bash",
					-- css
					"css",
					-- docker
					"dockerfile",
					-- go
					"go",
					"gomod",
					"gosum",
					-- hrml
					"html",
					-- javascript
					"javascript",
					"jsdoc",
					-- json
					"jsonc",
					"json",
					-- lua
					"lua",
					-- markdown
					"markdown",
					"markdown_inline",
					-- make
					"make",
					-- nix
					"nix",
					-- rust
					"rust",
					-- scss
					"scss",
					-- sql
					"sql",
					-- toml
					"toml",
					-- typescript
					"tsx",
					-- typescript
					"typescript",
					-- yaml
					"yaml",
				},
				ignore_install = {
					"org",
				},
			})
		end,
	},
}
