return {
  {
    -- https://github.com/uga-rosa/ddc-previewer-floating
    "uga-rosa/ddc-previewer-floating",
    config = function()
      require("ddc_previewer_floating").setup({
        ui = "pum",
        border = "single",
        window_options = {
          wrap = false,
          number = false,
          signcolumn = "no",
          cursorline = false,
          foldenable = false,
        },
      })
    end,
  },
}
