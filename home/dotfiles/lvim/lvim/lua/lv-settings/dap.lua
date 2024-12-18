-- dap
-- enabled dap
lvim.builtin.dap.active = true
-- keymaps
vim.keymap.set("n", "<F5>", ":lua require('dap').continue()<CR>", { noremap = true, silent = true, desc = "Continue" })
vim.keymap.set(
  "n",
  "<F10>",
  ":lua require('dap').step_over()<CR>",
  { noremap = true, silent = true, desc = "Step over" }
)
vim.keymap.set(
  "n",
  "<F11>",
  ":lua require('dap').step_into()<CR>",
  { noremap = true, silent = true, desc = "Step into" }
)
vim.keymap.set("n", "<F12>", ":lua require('dap').step_out()<CR>", { noremap = true, silent = true, desc = "Step out" })
