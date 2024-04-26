return {
  {
    -- https://github.com/rhysd/git-messenger.vim
    "rhysd/git-messenger.vim",
    cmd = "GitMessenger",
    init = function()
      vim.keymap.set("n", "<LEADER>gm", "<CMD>GitMessenger<CR>", { desc = "Show git blame on the current line" })
    end,
  },
}
