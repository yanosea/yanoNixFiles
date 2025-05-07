-- setup for image pasting
table.insert(lvim.plugins, {
  -- support for image pasting
  "HakonHarnes/img-clip.nvim",
  lazy = true,
  opts = {
    -- recommended settings
    default = {
      embed_image_as_base64 = false,
      prompt_for_file_name = false,
      drag_and_drop = {
        insert_mode = true,
      },
      -- required for Windows users
      use_absolute_path = true,
    },
  },
})
