-- automatically close and rename HTML/XML tags
return {
  {
    "windwp/nvim-ts-autotag",
    lazy = true,
    ft = { "html", "xml", "jsx", "tsx", "vue", "svelte", "php", "rescript", "astro" },
  },
}
