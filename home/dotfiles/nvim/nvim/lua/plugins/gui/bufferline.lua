return {
  {
    -- https://github.com/akinsho/bufferline.nvim
    "akinsho/bufferline.nvim",
    lazy = false,
    -- https://github.com/nvim-tree/nvim-web-devicons
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cond = not vim.g.started_by_firenvim,
    init = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          numbers = "ordinal",
          diagnostics = "nvim_lsp",
          diagnostics_update_in_insert = true,
          diagnostics_indicator = function(count, level, diagnostics_dict, context)
            if context.buffer:current() then
              return ""
            end
            return ""
          end,
          offsets = {
            {
              filetype = "NvimTree",
              text = "File Explorer",
              text_align = "left",
              separator = true,
            },
          },
          color_icon = true,
          get_element_icon = function(element)
            local icon, hl = require("nvim-web-devicons").get_icon_by_filetype(element.filetype, { default = false })
            return icon, hl
          end,
          show_buffer_close_icons = false,
          show_close_icon = false,
          show_buffer_icons = true,
          show_duplicate_prefix = false,
          show_tab_indicators = true,
          persist_buffer_sort = true,
          separator_style = "slope",
          enforce_regular_tabs = true,
          always_show_bufferline = true,
        },
      })
      vim.keymap.set("n", "<C-UP>", "<CMD>BufferLineMovePrev<CR>")
      vim.keymap.set("n", "<C-DOWN>", "<CMD>BufferLineMoveNext<CR>")
    end,
  },
}
