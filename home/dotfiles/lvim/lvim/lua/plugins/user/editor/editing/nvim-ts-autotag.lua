-- automatically close and rename HTML/XML tags
table.insert(lvim.plugins, {
  "windwp/nvim-ts-autotag",
  ft = { "html", "xml", "jsx", "tsx", "vue", "svelte", "php", "rescript", "astro" },
})
