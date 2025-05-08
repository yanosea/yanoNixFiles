-- folding
return {
  {
    "mfussenegger/nvim-treehopper",
    lazy = true,
    keys = { "zf" },
    init = function()
      -- keymaps
      -- folding
      vim.keymap.set(
        "n",
        "zf",
        function()
          require("tsht").nodes()
          vim.cmd("normal! zf")
        end,
        { silent = true, desc = "Nvim TreeHopper" }
      )
    end,
  },
}
