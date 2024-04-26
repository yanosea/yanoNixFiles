return {
  {
    -- https://github.com/tkmpypy/chowcho.nvim
    "tkmpypy/chowcho.nvim",
    lazy = false,
    -- https://zenn.dev/kawarimidoll/articles/daa39da5838567
    init = function()
      local select_window = function()
        local focusable_windows = 0

        for i = 1, vim.fn.winnr("$") do
          local id = vim.fn.win_getid(i)
          local conf = vim.api.nvim_win_get_config(id)

          if conf.focusable then
            focusable_windows = focusable_windows + 1

            if focusable_windows > 2 then
              require("chowcho").run()
              return
            end
          end
        end

        vim.api.nvim_command("wincmd w")
      end

      for _, mode in pairs({ "n", "x" }) do
        vim.keymap.set(mode, "<C-w><C-w>", select_window, { desc = "Select window" })
      end
    end,
    config = function()
      require("chowcho").setup({
        icon_enabled = true,
        active_border_color = "#d162cb",
        border_style = "rounded",
      })
    end,
  },
}
