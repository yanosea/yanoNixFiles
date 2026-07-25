-- Require the sketchybar module
-- selene: allow(unscoped_variables, incorrect_standard_library_use) -- Sbar must be a real global: every other file in this config reads it without `require`
Sbar = require("sketchybar")

-- Set the bar name, if you are using another bar instance than sketchybar
-- sbar.set_bar_name("bottom_bar")

-- Bundle the entire initial configuration into a single message to sketchybar
Sbar.begin_config()
require("bar")
require("default")
require("items")
Sbar.end_config()

-- Run the event loop of the sketchybar module (without this there will be no
-- callback functions executed in the lua module)
Sbar.event_loop()
