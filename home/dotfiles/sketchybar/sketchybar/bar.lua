local colors = require("colors")

-- Equivalent to the --bar domain
Sbar.bar({
  topmost = "window",
  height = 40,
  color = colors.bar.bg,
  padding_right = 2,
  padding_left = 2,
  y_offset = 5,
  margin = 10,
  corner_radius = 10,
  border_color = colors.grey,
  border_width = 1,
})
