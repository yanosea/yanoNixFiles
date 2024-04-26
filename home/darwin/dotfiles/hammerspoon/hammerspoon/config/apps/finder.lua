-- FInder
local finderBinding = {
  -- open file (ctrl + return)
  hs.hotkey.bind({ "ctrl" }, "return", nil, function()
    hs.eventtap.keyStroke({ "cmd" }, "o")
  end),
  -- rename (f2)
  hs.hotkey.bind({}, "f2", nil, function()
    hs.eventtap.keyStroke({}, "return")
  end),
  -- move to folder includes current directory (alt + up)
  hs.hotkey.bind({ "option" }, "up", nil, function()
    hs.eventtap.keyStroke({ "cmd" }, "up")
  end),
}
hs.window.filter
  .new("Finder")
  :subscribe(hs.window.filter.windowFocused, function()
    require("helper.util").EnableAll(finderBinding)
  end)
  :subscribe(hs.window.filter.windowUnfocused, function()
    require("helper.util").DisableAll(finderBinding)
  end)
