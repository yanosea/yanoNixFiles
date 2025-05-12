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
      local message = is_unnamed and "Save changes to unnamed buffer?" or fmt([[Save changes to "%s"?]], bufname)
      choice = fn.confirm(message, "&Yes\n&No\n&Cancel")
      if choice == 1 then
        if is_unnamed then
          -- for unnamed buffers, switch to the buffer before saving
          -- to properly show the filename prompt
          local current_buf = api.nvim_get_current_buf()
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
              if dir ~= "." and vim.fn.isdirectory(dir) == 0 then
                choice = fn.confirm(fmt("Directory '%s' doesn't exist. Create it?", dir), "&Yes\n&No", 1)
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
-- FormatUtils module for lsp formatting
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua
_G.FormatUtils = {
  -- filter function to determine which LSP client should handle formatting
  -- prioritizes efm-langserver if available
  format_filter = function(client)
    -- prioritize efm-langserver for formatting
    if client.name == "efm" then
      return true
    end
    -- check if other clients can format and efm is not available
    local has_efm = false
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      if c.name == "efm" then
        has_efm = true
        break
      end
    end
    -- if efm is not available, fallback to other clients with formatting capability
    if not has_efm and client.supports_method("textDocument/formatting") then
      return true
    end
    return false
  end,
  -- simple wrapper for vim.lsp.buf.format() to provide defaults
  format = function(opts)
    opts = opts or {}
    opts.filter = opts.filter or _G.FormatUtils.format_filter
    return vim.lsp.buf.format(opts)
  end,
  -- format current buffer or visual selection with LSP
  format_buffer = function()
    _G.FormatUtils.format({
      bufnr = vim.api.nvim_get_current_buf(),
      async = false,
    })
  end,
  -- setup format on save for specific filetypes
  setup_format_on_save = function(filetypes)
    local group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true })
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = group,
      callback = function()
        local current_ft = vim.bo.filetype
        for _, ft in ipairs(filetypes) do
          if current_ft == ft then
            _G.FormatUtils.format_buffer()
            break
          end
        end
      end,
    })
    return group
  end,
  -- check if efm-langserver is configured for the current filetype
  has_efm_formatter = function(filetype)
    filetype = filetype or vim.bo.filetype
    local clients = vim.lsp.get_clients({ bufnr = 0 })

    for _, client in ipairs(clients) do
      if client.name == "efm" then
        if client.config and client.config.filetypes then
          for _, ft in ipairs(client.config.filetypes) do
            if ft == filetype then
              return true
            end
          end
        end
      end
    end
    return false
  end,
  -- log formatting information for debugging
  log_format_info = function()
    local filetype = vim.bo.filetype
    local clients = vim.lsp.vim.lsp.get_clients({ bufnr = 0 })
    local info = {
      filetype = filetype,
      clients = {},
      has_efm = false,
    }
    for _, client in ipairs(clients) do
      local client_info = {
        name = client.name,
        supports_formatting = client.supports_method("textDocument/formatting"),
        filetypes = client.config and client.config.filetypes or {},
      }
      table.insert(info.clients, client_info)
      -- check if efm-langserver is available
      if client.name == "efm" then
        info.has_efm = true
      end
    end
    vim.notify(vim.inspect(info), vim.log.levels.INFO, {
      title = "Format Info",
      timeout = 5000,
    })
  end,
}
