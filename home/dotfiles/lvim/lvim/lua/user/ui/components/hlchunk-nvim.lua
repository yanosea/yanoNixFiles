-- show indent lines instead of lunarvim builtin indentblankline.nvim
table.insert(lvim.plugins, {
  "shellRaining/hlchunk.nvim",
  event = "VeryLazy",
  config = function()
    require("hlchunk").setup({
      chunk = {
        enable = true,
        notify = true,
        use_treesitter = true,
        support_filetypes = "",
        exclude_filetypes = {
          aerial = true,
          dashboard = true,
          help = true,
          lspinfo = true,
          lspsagafinder = true,
          packer = true,
          checkhealth = true,
          man = true,
          mason = true,
          NvimTree = true,
          ["neo-tree"] = true,
          plugin = true,
          lazy = true,
          TelescopePrompt = true,
          [""] = true,
          alpha = true,
          toggleterm = true,
          sagafinder = true,
          sagaoutline = true,
          better_term = true,
          fugitiveblame = true,
          Trouble = true,
          qf = true,
          Outline = true,
          starter = true,
          NeogitPopup = true,
          NeogitStatus = true,
          DiffviewFiles = true,
          DiffviewFileHistory = true,
          DressingInput = true,
          spectre_panel = true,
          zsh = true,
          registers = true,
          startuptime = true,
          OverseerList = true,
          Navbuddy = true,
          noice = true,
          notify = true,
          ["dap-repl"] = true,
          saga_codeaction = true,
          sagarename = true,
          cmp_menu = true,
          ["null-ls-info"] = true,
        },
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          right_arrow = ">",
        },
        style = {
          { fg = "#83c092" }, -- Everforest sage green
          { fg = "#e67e80" }, -- Everforest red
        },
        textobject = "",
        max_file_size = 1024 * 1024,
        error_sign = true,
      },
      indent = {
        enable = false,
        use_treesitter = true,
        chars = {
          "│",
        },
        style = {
          { fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui") },
        },
      },
      line_num = {
        enable = true,
        use_treesitter = true,
        style = "#83c092", -- Everforest sage green
      },
      blank = {
        enable = true,
        chars = {
          "․",
        },
        style = {
          vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui"),
        },
      },
    })
  end,
})
