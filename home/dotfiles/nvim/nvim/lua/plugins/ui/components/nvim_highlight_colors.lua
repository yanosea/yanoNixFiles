-- show colors by name and tailwindcss colors and hex values
return {
  {
    "brenoprata10/nvim-highlight-colors",
    lazy = true,
    ft = { "css", "scss", "html", "javascript", "typescript", "svelte", "vue", "tsx", "jsx" },
    config = function()
      require("nvim-highlight-colors").setup({
        render = "background",
        enable_named_colors = true,
        enable_tailwind = true,
      })
    end,
  },
}
