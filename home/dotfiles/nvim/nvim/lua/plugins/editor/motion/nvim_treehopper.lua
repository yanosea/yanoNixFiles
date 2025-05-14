-- folding
return {
  {
    "mfussenegger/nvim-treehopper",
    lazy = true,
    keys = { "zf" },
    init = function()
      -- keymaps
      -- smart folding
      vim.keymap.set("n", "zf", function()
        require("tsht").nodes()
        vim.cmd("normal! zf")
      end, { desc = "treehopper", silent = true })
    end,
  },
}
