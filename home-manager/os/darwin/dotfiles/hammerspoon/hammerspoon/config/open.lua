-- activity monitor
hs.hotkey.bind({ "ctrl", "shift" }, "escape", require("helper.util").OpenApp("Activity Monitor"))
-- new finder window
hs.hotkey.bind({ "cmd" }, "e", require("helper.util").OpenApp("Finder"))
-- system settings
hs.hotkey.bind({ "cmd" }, "i", require("helper.util").OpenApp("System Preferences"))
