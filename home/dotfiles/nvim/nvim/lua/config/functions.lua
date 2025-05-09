-- functions definitions
-- BufferKill function to close buffers with confirmation
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua
_G.BufferKill = function(kill_command, bufnr, force)
  kill_command = kill_command or "bd"
  local bo = vim.bo
  local api = vim.api
  local fmt = string.format
  local fn = vim.fn
  if bufnr == 0 or bufnr == nil then
    bufnr = api.nvim_get_current_buf()
  end
  -- check if buffer is valid
  local bufname = api.nvim_buf_get_name(bufnr)
  if not force then
    local choice
    if bo[bufnr].modified then
      -- check if buffer is unnamed
      local is_unnamed = bufname == ""
      local message = is_unnamed
        and "Save changes to unnamed buffer?"
        or fmt([[Save changes to "%s"?]], bufname)

      choice = fn.confirm(message, "&Yes\n&No\n&Cancel")
      if choice == 1 then
        if is_unnamed then
          -- for unnamed buffers, switch to the buffer before saving
          -- to properly show the filename prompt
          local current_buf = api.nvim_get_current_buf()
          local current_win = api.nvim_get_current_win()
          -- only switch if not already on the target buffer
          if current_buf ~= bufnr then
            api.nvim_set_current_buf(bufnr)
          end
          -- execute the interactive save command
          local ok, err = pcall(function()
            vim.cmd("w")
          end)
          -- if saving failed due to no filename, prompt for filename
          if not ok and string.match(err or "", "E32: No file name") then
            vim.cmd("redraw")
            local filename = vim.fn.input("Please enter filename to save: ")
            if filename and filename ~= "" then
              local dir = vim.fn.fnamemodify(filename, ":h")
              local basename = vim.fn.fnamemodify(filename, ":t")
              if dir ~= "." and vim.fn.isdirectory(dir) == 0 then
                local choice = fn.confirm(fmt("Directory '%s' doesn't exist. Create it?", dir), "&Yes\n&No", 1)
                if choice == 1 then
                  fn.mkdir(dir, "p")
                end
              end
              vim.cmd("write " .. vim.fn.fnameescape(filename))
            end
          end
          -- restore previous buffer if needed
          if current_buf ~= bufnr then
            api.nvim_set_current_buf(current_buf)
          end
        else
          -- for named buffers, use the original approach
          vim.api.nvim_buf_call(bufnr, function()
            vim.cmd("w")
          end)
        end
      elseif choice == 2 then
        force = true
      else
        return
      end
    elseif api.nvim_buf_get_option(bufnr, "buftype") == "terminal" then
      choice = fn.confirm(fmt([[Close "%s"?]], bufname), "&Yes\n&No\n&Cancel")
      if choice == 1 then
        force = true
      else
        return
      end
    end
  end
  -- get list of windows IDs with the buffer to close
  local windows = vim.tbl_filter(function(win)
    return api.nvim_win_get_buf(win) == bufnr
  end, api.nvim_list_wins())
  -- if there are no windows with the buffer, just delete it
  if force then
    kill_command = kill_command .. "!"
  end
  -- get list of active buffers
  local buffers = vim.tbl_filter(function(buf)
    return api.nvim_buf_is_valid(buf) and bo[buf].buflisted
  end, api.nvim_list_bufs())
  -- if there is only one buffer (which has to be the current one), vim will
  -- create a new buffer on :bd.
  -- for more than one buffer, pick the previous buffer (wrapping around if necessary)
  if #buffers > 1 and #windows > 0 then
    for i, v in ipairs(buffers) do
      if v == bufnr then
        local prev_buf_idx = i == 1 and #buffers or (i - 1)
        local prev_buffer = buffers[prev_buf_idx]
        for _, win in ipairs(windows) do
          api.nvim_win_set_buf(win, prev_buffer)
        end
      end
    end
  end
  -- check if buffer still exists, to ensure the target buffer wasn't killed
  -- due to options like bufhidden=wipe.
  if api.nvim_buf_is_valid(bufnr) and bo[bufnr].buflisted then
    vim.cmd(string.format("%s %d", kill_command, bufnr))
  end
end
