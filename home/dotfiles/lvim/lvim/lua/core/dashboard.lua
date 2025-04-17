-- dashboard config
-- define buttons
lvim.builtin.alpha.dashboard.section.buttons.entries = {}
local buttons = {
  { "f", "󰈞  Find File", "<CMD>Telescope find_files<CR>" },
  { "n", "  New File", "<CMD>ene!<CR>" },
  { "p", "  Projects ", "<CMD>Telescope projects<CR>" },
  { "r", "  Recent Files", ":Telescope oldfiles <CR>" },
  { "t", "󰊄  Find Text", "<CMD>Telescope live_grep<CR>" },
  { "l", "󰒲  Lazy", "<CMD>Lazy<CR>" },
  { "m", "󱌣  Mason Lsp", "<CMD>Mason<CR>" },
  { "T", "󰔱  Sync Tree-Sitter Parser", "<CMD>TSUpdateSync<CR>" },
  { "q", "󰅖  Quit", "<CMD>quit<CR>" },
}
for i, btn in ipairs(buttons) do
  lvim.builtin.alpha.dashboard.section.buttons.entries[i] = btn
end
