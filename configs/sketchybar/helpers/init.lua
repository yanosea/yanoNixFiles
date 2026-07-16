-- Add the sketchybar module to the package cpath
-- package.cpath = package.cpath .. ";/Users/" .. os.getenv("USER") .. "/.local/share/sketchybar_lua/?.so"
package.cpath = package.cpath .. ";/Users/" .. os.getenv("USER") .. "/.nix-profile/bin/?.so"

os.execute("(cd helpers && make)")
