-- an always-on highlight for a unique character in every word on a line to help you use f, F and family.
table.insert(lvim.plugins, {
  "unblevable/quick-scope",
  event = { "BufRead", "BufEnter" },
})
