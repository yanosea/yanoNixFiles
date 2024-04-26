local settings = require("settings")
local colors = require("colors")

-- Padding item required because of bracket
Sbar.add("item", { position = "right", width = settings.group_paddings })

local cal = Sbar.add("item", {
  icon = {
    color = colors.white,
    padding_left = 8,
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
  },
  label = {
    color = colors.white,
    padding_right = 8,
    width = 65,
    align = "right",
    font = { family = settings.font.numbers },
  },
  position = "right",
  update_freq = 1,
  padding_left = 1,
  padding_right = 1,
  background = {
    color = colors.bg2,
    border_color = colors.black,
    border_width = 1,
  },
})

-- Double border for calendar using a single item bracket
Sbar.add("bracket", { cal.name }, {
  background = {
    color = colors.transparent,
    height = 30,
    border_color = colors.grey,
  },
})

-- Padding item required because of bracket
Sbar.add("item", { position = "right", width = settings.group_paddings })

cal:subscribe({ "forced", "routine", "system_woke" }, function(_)
  cal:set({ icon = os.date("  %Y/%m/%d"), label = os.date("%H:%M:%S") })
end)
