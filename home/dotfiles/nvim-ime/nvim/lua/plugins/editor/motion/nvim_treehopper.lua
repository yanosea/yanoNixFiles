-- folding
return {
  {
    "mfussenegger/nvim-treehopper",
    keys = { "zf" },
    config = function()
      vim.keymap.set("n", "zf", function()
        require("tsht").nodes()
        vim.cmd("normal! zf")
      end, { silent = true, desc = "Nvim TreeHopper" })
    end,
  },
}
