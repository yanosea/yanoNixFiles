-- syntax highlighting and code folding
return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ts = require("nvim-treesitter")
			local ensure_installed = {
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
				-- docker
				"dockerfile",
				-- go
				"go",
				"gomod",
				"gosum",
				-- lua
				"lua",
				-- make
				"make",
				-- markdown
				"markdown",
				"markdown_inline",
				-- nix
				"nix",
				-- rust
				"rust",
				-- shell
				"bash",
				-- sql
				"sql",
				-- toml
				"toml",
				-- typescript
				"javascript",
				"jsdoc",
				"tsx",
				"typescript",
				-- web
				"astro",
				"css",
				"html",
				"json",
				"jsonc",
				"scss",
				-- yaml
				"yaml",
			}
			-- check for installed parsers and install missing ones
			local installed = ts.get_installed()
			local missing = vim.tbl_filter(function(p)
				return not vim.tbl_contains(installed, p)
			end, ensure_installed)
			if #missing > 0 then
				ts.install(missing)
			end
			vim.api.nvim_create_autocmd("FileType", {
				callback = function()
					pcall(vim.treesitter.start)
				end,
			})
		end,
	},
}
