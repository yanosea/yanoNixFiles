-- extends f, F, t, T commands
table.insert(lvim.plugins, {
  "rhysd/clever-f.vim",
  event = { "BufRead", "BufEnter" },
})
