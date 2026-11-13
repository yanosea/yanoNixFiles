-- monitors
hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0", scale = "auto" })
hl.monitor({ output = "DP-3", mode = "1920x1080@239.96", position = "1920x0", scale = "auto" })
hl.monitor({ output = "DP-2", mode = "1920x1080@60", position = "3840x0", scale = "auto" })
hl.monitor({ output = "Unknown-1", disabled = true })
-- workspaces
for ws, monitor in ipairs({
	"HDMI-A-1",
	"HDMI-A-1",
	"HDMI-A-1",
	"DP-3",
	"DP-3",
	"DP-3",
	"DP-2",
	"DP-2",
	"DP-2",
}) do
	hl.workspace_rule({ workspace = tostring(ws), monitor = monitor })
end
hl.config({
	-- general
	general = {
		border_size = 2,
		gaps_in = 5,
		gaps_out = 10,
		col = {
			inactive_border = "rgba(475266aa)",
			active_border = { colors = { "rgba(83c092ee)", "rgba(7fbbb3ee)" }, angle = 45 },
		},
		layout = "dwindle",
		allow_tearing = false,
	},
	-- decotation
	decoration = {
		rounding = 0,
		blur = {
			enabled = false,
		},
		shadow = {
			enabled = true,
			range = 5,
			render_power = 4,
			color = "rgba(2d353bee)",
		},
	},
	-- animation
	animations = {
		enabled = true,
	},
	-- input
	input = {
		kb_layout = "us",
		sensitivity = 0.75,
		follow_mouse = 1,
		scroll_factor = 0.25,
		natural_scroll = true,
		touchpad = {
			natural_scroll = true,
			scroll_factor = 0.25,
		},
	},
	-- misc
	misc = {
		disable_hyprland_logo = false,
		font_family = "plemoljp-nf",
		force_default_wallpaper = 2,
		animate_manual_resizes = true,
		animate_mouse_windowdragging = true,
	},
	-- layout
	dwindle = {
		preserve_split = true,
	},
})
hl.curve("myBezier", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 7, bezier = "myBezier" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7, bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "fade", enabled = true, speed = 7, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6, bezier = "default" })
-- autostart
hl.on("hyprland.start", function()
	-- systemd session target
	hl.exec_cmd("systemctl --user start hyprland-session.target")
	-- blueman
	hl.exec_cmd("blueman-applet")
	-- focus workspace 4 on startup
	hl.dispatch(hl.dsp.focus({ workspace = "4" }))
	-- wallpaper
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("sleep 5 && $HOME/.local/bin/wallpaper-engine autostart")
	-- bar
	hl.exec_cmd("qs")
	-- ime
	hl.exec_cmd("sleep 1 && fcitx5 -D")
	-- easyeffects
	hl.exec_cmd("sleep 10 && easyeffects -w")
	-- vesktop
	hl.exec_cmd("vesktop", { workspace = "special:vesktop silent" })
	-- spotify
	hl.exec_cmd("spotify", { workspace = "special:spotify silent" })
	-- btop in special workspace
	hl.exec_cmd("wezterm -e btop", { workspace = "special:btop silent" })
	-- steam
	hl.exec_cmd("sleep 5 && rm -f ~/.steam/steam.pid && systemd-run --user steam")
	-- docker (rootless autostart disabled globally to avoid greetd's greeter session; start it here instead)
	hl.exec_cmd("systemctl --user start docker")
	-- insync
	hl.exec_cmd("sleep 5 && insync start")
	-- rustdesk tray (the root --service reads the session env off this process; without it --server never sees the compositor)
	hl.exec_cmd("sleep 5 && rustdesk --tray")
end)
-- env
-- for graphic
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
-- timezone (PAM sets TZDIR but hyprland drops it, leaving timedatectl on +0000)
hl.env("TZDIR", "/etc/zoneinfo")
-- windowrule
-- vim via wezterm for ime
hl.window_rule({ match = { class = "^(FloatingVim)$" }, float = true })
-- special workspace auto-placement
-- vesktop
hl.window_rule({ match = { class = "^(vesktop)$" }, workspace = "special:vesktop silent" })
-- spotify
hl.window_rule({ match = { class = "^(spotify)$" }, workspace = "special:spotify silent" })
-- steam
hl.window_rule({ match = { class = "^(steam)$", title = "^(Steam)$" }, tile = true })
hl.window_rule({ match = { class = "^(steam)$" }, workspace = "special:game silent" })
-- bind
-- mainmod
local mainMod = "ALT"
-- window management with keyboard
for key, dir in pairs({ H = "left", J = "down", K = "up", L = "right" }) do
	-- move window focus
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ direction = dir }))
	-- move active window
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end
-- resize active window
hl.bind(mainMod .. " + left", hl.dsp.window.resize({ x = -20, y = 0, relative = true }))
hl.bind(mainMod .. " + right", hl.dsp.window.resize({ x = 20, y = 0, relative = true }))
hl.bind(mainMod .. " + up", hl.dsp.window.resize({ x = 0, y = -20, relative = true }))
hl.bind(mainMod .. " + down", hl.dsp.window.resize({ x = 0, y = 20, relative = true }))
-- tailing window vertically
hl.bind(mainMod .. " + S", hl.dsp.layout("togglesplit"))
-- float active window
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }))
-- maximize active window (keep bar visible)
hl.bind(mainMod .. " + X", hl.dsp.window.fullscreen({ mode = "maximized" }))
-- fullscreen active window (hide bar)
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.window.fullscreen_state({ internal = 2, client = -1 }))
-- workspace management with keyboard
for ws, key in ipairs({ "Q", "W", "E", "R", "T", "Y", "U", "I", "O" }) do
	-- move workspace focus
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = tostring(ws) }))
	-- move active window to workspace and focus
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(ws), follow = true }))
end
-- move workspace
hl.bind(mainMod .. " + SHIFT + A", hl.dsp.workspace.move({ monitor = "l" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.workspace.move({ monitor = "r" }))
-- window management with mouse
-- move window with mouse
hl.bind(mainMod .. " + SHIFT + mouse:272", hl.dsp.window.drag(), { mouse = true })
-- resize window with mouse
hl.bind(mainMod .. " + SHIFT + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- shortcuts
-- application launcher
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
-- btop (like taskmgr)
hl.bind("CTRL + SHIFT + ESCAPE", hl.dsp.workspace.toggle_special("btop"))
-- clipboard history via quickshell launcher
hl.bind("CTRL + SHIFT + Q", hl.dsp.exec_cmd("qs ipc call launcher clipboard"))
-- browser
hl.bind("SUPER + B", hl.dsp.exec_cmd("vivaldi"))
-- nemo (like explorer)
hl.bind("SUPER + E", hl.dsp.exec_cmd("nemo"))
-- special workspace
hl.bind(mainMod .. " + slash", hl.dsp.workspace.toggle_special("stash"))
hl.bind(mainMod .. " + SHIFT + slash", hl.dsp.window.move({ workspace = "special:stash", follow = true }))
hl.bind("SUPER + V", hl.dsp.workspace.toggle_special("vesktop"))
hl.bind("SUPER + M", hl.dsp.workspace.toggle_special("spotify"))
hl.bind("SUPER + G", hl.dsp.workspace.toggle_special("game"))
-- kill active window
hl.bind("SUPER + Q", hl.dsp.window.close())
-- terminal
hl.bind("SUPER + T", hl.dsp.exec_cmd("wezterm"))
-- lock screen
hl.bind("SUPER + L", hl.dsp.exec_cmd("qs ipc call lockScreen lock"))
-- screenshot
-- select area and clipboard-only
hl.bind("SUPER + S", hl.dsp.exec_cmd("hyprshot -z -m region --clipboard-only"))
-- select window and clipboard-only
hl.bind("SUPER + X", hl.dsp.exec_cmd("hyprshot -z -m window --clipboard-only"))
-- select monitor and clipboard-only
hl.bind("SUPER + Z", hl.dsp.exec_cmd("hyprshot -z -m output --clipboard-only"))
-- select area and save
hl.bind(
	"SUPER + SHIFT + S",
	hl.dsp.exec_cmd([[hyprshot -z -m region -o ~/google_drive/pics -f "$(date +%Y-%m-%d-%H-%M-%S).png"]])
)
-- select window and save
hl.bind(
	"SUPER + SHIFT + X",
	hl.dsp.exec_cmd([[hyprshot -z -m window -o ~/google_drive/pics -f "$(date +%Y-%m-%d-%H-%M-%S).png"]])
)
-- select monitor and save
hl.bind(
	"SUPER + SHIFT + Z",
	hl.dsp.exec_cmd([[hyprshot -z -m output -o ~/google_drive/pics -f "$(date +%Y-%m-%d-%H-%M-%S).png"]])
)
-- recording
local recAudio = [[--audio="alsa_output.usb-Roland_Rubix24-00.analog-surround-40.monitor" --audio-volume=1.5]]
for key, output in pairs({
	Q = "HDMI-A-1", -- record monitor 1 (left)
	W = "DP-3", -- record monitor 2 (center)
	E = "DP-2", -- record monitor 3 (right)
}) do
	hl.bind(
		"SUPER + SHIFT + " .. key,
		hl.dsp.exec_cmd(
			"wf-recorder -a -o "
				.. output
				.. " "
				.. recAudio
				.. " -f ~/google_drive/movs/rec/$(date +%Y-%m-%d-%H-%M-%S)-"
				.. output
				.. ".mp4"
		)
	)
end
-- stop recording
hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("killall -s SIGINT wf-recorder"))
-- color picker
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a -f hex"))
-- reload config
-- reload hyprland config
hl.bind("SUPER + SHIFT + H", hl.dsp.exec_cmd([[hyprctl reload && notify-send "Hyprland" "Configuration reloaded!"]]))
-- reload quickshell config
hl.bind(
	"SUPER + SHIFT + B",
	hl.dsp.exec_cmd(
		[[pkill quickshell; qs & sleep 3 && notify-send "QuickShell" "Configuration reloaded!" && $HOME/.local/bin/wallpaper-engine autostart]]
	)
)
-- system controls
-- reboot
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("qs ipc call sessionMenu reboot"))
-- shutdown
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("qs ipc call sessionMenu shutdown"))
-- logout
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("qs ipc call sessionMenu logout"))
