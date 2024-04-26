-- automatically close and rename HTML/XML tags
table.insert(lvim.plugins, {
  "windwp/nvim-ts-autotag",
  event = { "BufRead", "BufEnter" },
  init = function() end,
})
