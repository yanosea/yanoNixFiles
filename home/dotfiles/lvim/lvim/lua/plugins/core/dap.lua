-- dap config
-- enabled dap
lvim.builtin.dap.active = true
-- keymaps
-- F5 : continue
vim.keymap.set("n", "<F5>", ":lua require('dap').continue()<CR>", { noremap = true, silent = true, desc = "Continue" })
-- F10 : step over
vim.keymap.set(
  "n",
  "<F10>",
  ":lua require('dap').step_over()<CR>",
  { noremap = true, silent = true, desc = "Step over" }
)
-- F11 : step into
vim.keymap.set(
  "n",
  "<F11>",
  ":lua require('dap').step_into()<CR>",
  { noremap = true, silent = true, desc = "Step into" }
)
-- F12 : step out
vim.keymap.set("n", "<F12>", ":lua require('dap').step_out()<CR>", { noremap = true, silent = true, desc = "Step out" })
