return {
  {
    -- https://github.com/nvim-telescope/telescope.nvim
    "nvim-telescope/telescope.nvim",
    lazy = true,
    dependencies = {
      -- https://github.com/nvim-lua/plenary.nvim
      "nvim-lua/plenary.nvim",
      -- https://github.com/nvim-tree/nvim-web-devicons
      "nvim-tree/nvim-web-devicons",
      -- extensions
      --https://github.com/nvim-telescope/telescope-fzy-native.nvim
      "nvim-telescope/telescope-fzy-native.nvim",
      -- https://github.com/tsakirist/telescope-lazy.nvim
      "tsakirist/telescope-lazy.nvim",
      -- https://github.com/nvim-telescope/telescope-ui-select.nvim
      "nvim-telescope/telescope-ui-select.nvim",
      -- https://github.com/Allianaab2m/telescope-kensaku.nvim
      "Allianaab2m/telescope-kensaku.nvim",
      -- https://github.com/nvim-telescope/telescope-file-browser.nvim
      "nvim-telescope/telescope-file-browser.nvim",
      -- https://github.com/fdschmidt93/telescope-egrepify.nvim
      "fdschmidt93/telescope-egrepify.nvim",
    },
    cmd = "Telescope",
    init = function()
      vim.keymap.set("n", "<LEADER>B", "<CMD>Telescope buffers<CR>")
      vim.keymap.set("n", "<LEADER>E", function()
        return "<CMD>Telescope file_browser cwd=" .. vim.fn.expand("%:p:h") .. "<CR>"
      end, { silent = true, expr = true })
      vim.keymap.set("n", "<LEADER>F", "<CMD>Telescope find_files<CR>")
      vim.keymap.set("n", "<LEADER>G", "<CMD>Telescope egrepify<CR>")
      vim.keymap.set("n", "<LEADER>H", "<CMD>Telescope help_tags<CR>")
      vim.keymap.set("n", "<LEADER>K", "<CMD>Telescope kensaku<CR>")
      vim.keymap.set("n", "<LEADER>L", "<CMD>Telescope lazy<CR>")
      vim.keymap.set("n", "<LEADER>O", "<CMD>Telescope oldfiles<CR>")
    end,
    config = function()
      ---@diagnostic disable-next-line: redundant-parameter
      require("telescope").setup({
        defaults = {
          prompt_prefix = " ",
          layout_strategy = "vertical",
          layout_config = {
            vertical = {
              width = 0.8,
              height = 0.9,
              prompt_position = "bottom",
            },
          },
          preview = { treesitter = false },
          file_ignore_patterns = { "^.git/" },
          vimgrep_arguments = {
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
          },
        },
        pickers = {
          find_files = { hidden = true },
          live_grep = {},
        },
        extensions = {
          fzy_native = {
            override_generic_sorter = false,
            override_file_sorter = true,
          },
          lazy = {
            theme = "ivy",
            show_icon = true,
          },
          file_browser = {
            hidden = true,
            respect_gitignore = false,
            mappings = {
              ["n"] = {
                ["c"] = require("telescope._extensions.file_browser.actions").create,
                ["r"] = require("telescope._extensions.file_browser.actions").rename,
                ["m"] = require("telescope._extensions.file_browser.actions").move,
                ["y"] = require("telescope._extensions.file_browser.actions").copy,
                ["d"] = require("telescope._extensions.file_browser.actions").remove,
                ["o"] = require("telescope._extensions.file_browser.actions").open,
                ["g"] = require("telescope._extensions.file_browser.actions").goto_parent_dir,
                ["h"] = require("telescope._extensions.file_browser.actions").goto_home_dir,
                ["w"] = require("telescope._extensions.file_browser.actions").goto_cwd,
              },
            },
          },
        },
      })
      require("telescope").load_extension("fzy_native")
      require("telescope").load_extension("lazy")
      require("telescope").load_extension("ui-select")
      require("telescope").load_extension("kensaku")
      require("telescope").load_extension("file_browser")
      require("telescope").load_extension("egrepify")
    end,
  },
}
