local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

-- Execute the event provider binary which provides the event "network_update"
-- for the network interface "en0", which is fired every 2.0 seconds.
Sbar.exec(
	"killall network_load >/dev/null; $CONFIG_DIR/helpers/event_providers/network_load/bin/network_load en0 network_update 2.0"
)

local popup_width = 250

local wifi_up = Sbar.add("item", "widgets.wifi1", {
	position = "right",
	padding_left = -5,
	width = 0,
	icon = {
		padding_right = 0,
		font = {
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		string = icons.wifi.upload,
	},
	label = {
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		color = colors.red,
		string = "??? Bps",
	},
	y_offset = 4,
})

local wifi_down = Sbar.add("item", "widgets.wifi2", {
	position = "right",
	padding_left = -5,
	icon = {
		padding_right = 0,
		font = {
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		string = icons.wifi.download,
	},
	label = {
		font = {
			family = settings.font.numbers,
			style = settings.font.style_map["Bold"],
			size = 9.0,
		},
		color = colors.blue,
		string = "??? Bps",
	},
	y_offset = -4,
})

local wifi = Sbar.add("item", "widgets.wifi.padding", {
	position = "right",
	label = { drawing = false },
})

-- Background around the item
local wifi_bracket = Sbar.add("bracket", "widgets.wifi.bracket", {
	wifi.name,
	wifi_up.name,
	wifi_down.name,
}, {
	background = { color = colors.bg1 },
	popup = { align = "center", height = 30 },
})

local ssid = Sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		font = {
			style = settings.font.style_map["Bold"],
		},
		string = icons.wifi.router,
	},
	width = popup_width,
	align = "center",
	label = {
		font = {
			size = 15,
			style = settings.font.style_map["Bold"],
		},
		max_chars = 18,
		string = "????????????",
	},
	background = {
		height = 2,
		color = colors.grey,
		y_offset = -15,
	},
})

local hostname = Sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "Hostname:",
		width = popup_width / 2,
	},
	label = {
		max_chars = 20,
		string = "????????????",
		width = popup_width / 2,
		align = "right",
	},
})

local ip = Sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "IP:",
		width = popup_width / 2,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
	},
})

local mask = Sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "Subnet mask:",
		width = popup_width / 2,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
	},
})

local router = Sbar.add("item", {
	position = "popup." .. wifi_bracket.name,
	icon = {
		align = "left",
		string = "Router:",
		width = popup_width / 2,
	},
	label = {
		string = "???.???.???.???",
		width = popup_width / 2,
		align = "right",
	},
})

Sbar.add("item", { position = "right", width = settings.group_paddings })

wifi_up:subscribe("network_update", function(env)
	local up_color = (env.upload == "000 Bps") and colors.grey or colors.red
	local down_color = (env.download == "000 Bps") and colors.grey or colors.blue
	wifi_up:set({
		icon = { color = up_color },
		label = {
			string = env.upload,
			color = up_color,
		},
	})
	wifi_down:set({
		icon = { color = down_color },
		label = {
			string = env.download,
			color = down_color,
		},
	})
end)

wifi:subscribe({ "wifi_change", "system_woke" }, function(_)
	Sbar.exec("ipconfig getifaddr en0", function(ip_temp)
		local connected = not (ip_temp == "")
		wifi:set({
			icon = {
				string = connected and icons.wifi.connected or icons.wifi.disconnected,
				color = connected and colors.white or colors.red,
			},
		})
	end)
end)

local function hide_details()
	wifi_bracket:set({ popup = { drawing = false } })
end

local function toggle_details()
	local should_draw = wifi_bracket:query().popup.drawing == "off"
	if should_draw then
		wifi_bracket:set({ popup = { drawing = true } })
		Sbar.exec("networksetup -getcomputername", function(result)
			hostname:set({ label = result })
		end)
		Sbar.exec("ipconfig getifaddr en0", function(result)
			ip:set({ label = result })
		end)
		Sbar.exec("ipconfig getsummary en0 | awk -F ' SSID : '  '/ SSID : / {print $2}'", function(result)
			ssid:set({ label = result })
		end)
		Sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Subnet mask: ' '/^Subnet mask: / {print $2}'", function(result)
			mask:set({ label = result })
		end)
		Sbar.exec("networksetup -getinfo Wi-Fi | awk -F 'Router: ' '/^Router: / {print $2}'", function(result)
			router:set({ label = result })
		end)
	else
		hide_details()
	end
end

wifi_up:subscribe("mouse.clicked", toggle_details)
wifi_down:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.clicked", toggle_details)
wifi:subscribe("mouse.exited.global", hide_details)

local function copy_label_to_clipboard(env)
	local label = Sbar.query(env.NAME).label.value
	Sbar.exec('echo "' .. label .. '" | pbcopy')
	Sbar.set(env.NAME, { label = { string = icons.clipboard, align = "center" } })
	Sbar.delay(1, function()
		Sbar.set(env.NAME, { label = { string = label, align = "right" } })
	end)
end

ssid:subscribe("mouse.clicked", copy_label_to_clipboard)
hostname:subscribe("mouse.clicked", copy_label_to_clipboard)
ip:subscribe("mouse.clicked", copy_label_to_clipboard)
mask:subscribe("mouse.clicked", copy_label_to_clipboard)
router:subscribe("mouse.clicked", copy_label_to_clipboard)
