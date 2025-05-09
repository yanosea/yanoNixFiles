-- bufferline config
-- keymaps is set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>bj>)
return {
  {
    "akinsho/bufferline.nvim",
    lazy = true,
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("bufferline").setup({
        highlights = {
          background = {
            italic = true,
          },
          buffer_selected = {
            bold = true,
          },
        },
        options = {
          offsets = {
            {
              filetype = "undotree",
              text = "Undotree",
              highlight = "PanelHeading",
              padding = 1,
            },
            {
              filetype = "NvimTree",
              text = "Explorer",
              highlight = "PanelHeading",
              padding = 1,
            },
            {
              filetype = "DiffviewFiles",
              text = "Diff View",
              highlight = "PanelHeading",
              padding = 1,
            },
            {
              filetype = "flutterToolsOutline",
              text = "Flutter Outline",
              highlight = "PanelHeading",
            },
            {
              filetype = "lazy",
              text = "Lazy",
              highlight = "PanelHeading",
              padding = 1,
            },
          },
          separator_style = "slope",
          show_buffer_close_icons = false,
          show_buffer_icons = true,
        },
      })
    end,
  },
}
