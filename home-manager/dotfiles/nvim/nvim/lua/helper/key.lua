local ctrl_prefix

local osName = os.getenv("OS")
if osName == "Darwin" then
  ctrl_prefix = "D-"
else
  ctrl_prefix = "C-"
end

local ctrl_keymap_set = function(prefix, key)
  return "<" .. prefix .. key .. ">"
end

local ctrl_with_leader_keymap_set = function(prefix, key)
  return "<LEADER><" .. prefix .. key .. ">"
end

return {
  ctrl_prefix = ctrl_prefix,
  ctrl_keymap_set = ctrl_keymap_set,
  ctrl_with_leader_keymap_set = ctrl_with_leader_keymap_set,
}
