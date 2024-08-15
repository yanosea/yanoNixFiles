-- go debugging
table.insert(lvim.plugins, {
  "leoluz/nvim-dap-go",
  ft = { "go" },
  init = function()
    require("dap-go").setup({
      dap_configurations = {
        go = {
          {
            type = "go",
            name = "Debug the golang",
            request = "launch",
            program = "${file}",
          },
          {
            type = "go",
            name = "Debug the golang test",
            request = "launch",
            mode = "test",
            program = "${file}",
          },
          {
            type = "go",
            name = "Debug test (go.mod)",
            request = "launch",
            mode = "test",
            program = "./${relativeFileDirname}",
          },
        },
      },
    })
  end,
})
