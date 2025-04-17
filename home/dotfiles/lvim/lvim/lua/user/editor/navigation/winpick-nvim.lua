-- window selection
table.insert(lvim.plugins, {
  "gbrlsnchs/winpick.nvim",
  keys = { "<C-w><C-w>" },
  init = function()
    require("winpick").setup({
      border = "single",
      chars = { "A", "S", "D", "F", "J", "K", "L", ";" },
      filter = function(winid)
        local is_excluded = false
        local bufnr = vim.api.nvim_win_get_buf(winid)
        local filetype = vim.bo[bufnr].filetype

        local excluded_filetypes = {
          "noice",
        }

        if vim.tbl_contains(excluded_filetypes, filetype) then
          is_excluded = true
        end

        return not is_excluded
      end,
    })

    vim.api.nvim_set_keymap(
      "n",
      "<C-w><C-w>",
      "<CMD>lua WinPick()<CR>",
      { noremap = true, silent = true, desc = "Pick Windows" }
    )
  end,
})

function WinPick()
  local all_win_ids = vim.api.nvim_tabpage_list_wins(0)
  local excluded_win_count = 0

  for _, winid in ipairs(all_win_ids) do
    local bufnr = vim.api.nvim_win_get_buf(winid)
    local filetype = vim.bo[bufnr].filetype
    if filetype == "noice" then
      excluded_win_count = excluded_win_count + 1
    end
  end

  local total_win_count = #all_win_ids
  local eligible_win_count = total_win_count - excluded_win_count

  if eligible_win_count < 3 then
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w><C-w>", true, false, true), "n", true)
  else
    local success, winid = pcall(require("winpick").select)

    if success and winid then
      vim.api.nvim_set_current_win(winid)
    end
  end
end
