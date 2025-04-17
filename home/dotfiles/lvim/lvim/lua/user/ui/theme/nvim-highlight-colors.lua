-- show colors by name and tailwindcss colors and hex values
table.insert(lvim.plugins, {
  "brenoprata10/nvim-highlight-colors",
  ft = { "css", "scss", "html", "javascript", "typescript", "svelte", "vue", "tsx", "jsx" },
  config = function()
    require("nvim-highlight-colors").setup({
      render = "background",
      enable_named_colors = true,
      enable_tailwind = true,
    })
  end,
})
