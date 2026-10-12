local mode = require("lua.mode")
local stage = require("lua.stage")

local terminal = "foot"
local browser = "zen-browser"

local directions = {
	{ key = "LEFT", msg = "l", name = "left", dx = -1, dy = 0 },
	{ key = "RIGHT", msg = "r", name = "right", dx = 1, dy = 0 },
	{ key = "UP", msg = "u", name = "up", dx = 0, dy = -1 },
	{ key = "DOWN", msg = "d", name = "down", dx = 0, dy = 1 },
}

local workspace_count = 10
local cursor_step = 20

-- Layout binds, swapped live by hypr-layout-toggle through `hyprctl eval`,
-- so apply_layout_binds has to stay global.
-- The stage (lua/stage.lua): no drag resizes it, so heights are on keys.
local stage_binds = {
	{ "SUPER + SHIFT + RETURN", stage.put_on_stage, "Put the focused window on the stage" },
	{ "SUPER + A", stage.focus_view, "Fullscreen inside the stage" },
	{ "SUPER + equal", stage.resize("taller"), "Stage: taller side window" },
	{ "SUPER + minus", stage.resize("shorter"), "Stage: shorter side window" },
}

local scrolling_binds = {
	{ "SUPER + SHIFT + RETURN", hl.dsp.layout("promote") },
	{ "SUPER + SHIFT + CONTROL + RIGHT", hl.dsp.layout("swapcol r") },
	{ "SUPER + SHIFT + CONTROL + LEFT", hl.dsp.layout("swapcol l") },
	{ "SUPER + F", hl.dsp.layout("fit active") },
	{ "SUPER + SHIFT + F", hl.dsp.layout("fit visible") },
}

function apply_layout_binds(name)
	for _, d in ipairs(directions) do
		hl.unbind("SUPER + " .. d.key)
	end
	for _, b in ipairs(scrolling_binds) do
		hl.unbind(b[1])
	end
	for _, b in ipairs(stage_binds) do
		hl.unbind(b[1])
	end

	if name == "scrolling" then
		for _, d in ipairs(directions) do
			hl.bind("SUPER + " .. d.key, hl.dsp.layout("focus " .. d.msg), { repeating = true })
		end
		for _, b in ipairs(scrolling_binds) do
			hl.bind(b[1], b[2])
		end
	else
		for _, d in ipairs(directions) do
			hl.bind("SUPER + " .. d.key, hl.dsp.focus({ direction = d.name }), { repeating = true })
		end
	end

	-- Streamer mode: the core moves above, plus the stage keys.
	if name == "stage" then
		for _, b in ipairs(stage_binds) do
			hl.bind(b[1], b[2], { description = b[3] })
		end
	end
end

apply_layout_binds(mode.streamer and "stage" or "scrolling")

-- In streamer mode the binds are the stage's; a flip would swap them out.
if not mode.streamer then
	hl.bind("SUPER + O", hl.dsp.exec_cmd("hypr-layout-toggle"), { description = "Toggle scrolling/dwindle layout" })
end

-- Workspaces
for i = 1, workspace_count do
	hl.bind("SUPER + " .. tostring(i % workspace_count), hl.dsp.focus({ workspace = i }))
	hl.bind("SUPER + SHIFT + " .. tostring(i % workspace_count), hl.dsp.window.move({ workspace = i }))
end

hl.bind("SUPER + grave", hl.dsp.workspace.toggle_special("communication"))
hl.bind("SUPER + SHIFT + grave", hl.dsp.window.move({ workspace = "special:communication" }))
hl.bind("SUPER + tab", hl.dsp.workspace.toggle_special("music"))
hl.bind("SUPER + SHIFT + tab", hl.dsp.window.move({ workspace = "special:music" }))
hl.bind("SUPER + T", hl.dsp.workspace.toggle_special("torrents"))
hl.bind("SUPER + ALT + T", hl.dsp.window.move({ workspace = "special:torrents" }))

-- Windows
-- In streamer mode SUPER+A is a stage bind (fullscreen inside the stage).
if not mode.streamer then
	hl.bind("SUPER + A", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
end
hl.bind("SUPER + D", hl.dsp.window.pseudo())
hl.bind("SUPER + G", hl.dsp.window.pin())
hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + S", hl.dsp.window.float({ action = "toggle" }))
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd("uxtrace record toggle --keys"), { description = "Record for an agent" })

for _, d in ipairs(directions) do
	hl.bind("SUPER + SHIFT + " .. d.key, hl.dsp.window.move({ direction = d.name }), { repeating = true })
	hl.bind("SUPER + ALT + " .. d.key, hl.dsp.window.swap({ direction = d.name }), { repeating = true })
end

-- Mouse and keyboard drag/resize
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + X", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + SHIFT + X", hl.dsp.window.resize(), { mouse = true })

-- Fixed-ratio fit scripts
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("hypr-16x9"), { description = "Toggle locked 16:9 fit" })
hl.bind("SUPER + SHIFT + CONTROL + D", hl.dsp.exec_cmd("hypr-16x9 -r 8:9"), { description = "Toggle locked 8:9 fit" })

-- Apps
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("banditshell toggle panel launcher"))
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind("SUPER + B", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd(browser .. " --private-window"))
hl.bind("SUPER + E", hl.dsp.exec_cmd("banditshell toggle panel files"))

-- Panels
hl.bind("SUPER + Z", hl.dsp.exec_cmd("banditshell toggle panel calculator"))
hl.bind("XF86Calculator", hl.dsp.exec_cmd("banditshell toggle panel calculator"), { locked = true })
hl.bind("SUPER + M", hl.dsp.exec_cmd("banditshell toggle panel media"))
hl.bind("SUPER + K", hl.dsp.exec_cmd("banditshell toggle sidebar"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("banditshell toggle panel clipboard"))

-- Bare and streamer: scripts/hypr-mode sets the flag and reloads; the reload
-- derives gaps, rounding, layout and binds from it (lua/mode.lua). While
-- streaming, SUPER+SHIFT+K refuses, so the chrome can't land on stream.
hl.bind("SUPER + SHIFT + K", hl.dsp.exec_cmd("~/.config/hypr/scripts/hypr-mode bare toggle"), { description = "Bare: shell chrome off, square windows" })
hl.bind("SUPER + CTRL + K", hl.dsp.exec_cmd("~/.config/hypr/scripts/hypr-mode streamer toggle"), { description = "Streamer mode: bare plus a 16:9 stage" })

-- Session
hl.bind("SUPER + P", hl.dsp.exec_cmd("banditshell toggle panel session"))
hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind("SUPER + SHIFT + ESCAPE", hl.dsp.exec_cmd("banditshell close"))
hl.bind("SUPER + CTRL + SHIFT + F4", hl.dsp.exit())

-- Clipboard
hl.bind("SUPER + J", hl.dsp.exec_cmd("~/.local/bin/ollama-clipboard"))
hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd("env TYPE_CLIPBOARD_DEBUG=1 /home/bandit/.local/bin/type-clipboard"))

-- Capture
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("banditshell dispatch picker freezeclip"))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a --format=hex"))
hl.bind(
	"SUPER + SHIFT + T",
	hl.dsp.exec_cmd([[region=$(slurp) && grim -g "$region" - | tesseract stdin stdout -l eng | wl-copy]])
)
hl.bind("SUPER + ALT + C", hl.dsp.exec_cmd("regionpick"), { description = "Region cam: pick a region" })
hl.bind("SUPER + ALT + SHIFT + C", hl.dsp.exec_cmd("regionpick clear"), { description = "Region cam: reset" })

-- Voice
hl.bind("SUPER + R", hl.dsp.exec_cmd("voice key"))
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("voice key stream"))
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("voice retype"))

-- Live only while a recording runs.
hl.define_submap("voice", function()
	hl.bind("SUPER + R", hl.dsp.exec_cmd("voice key"))
	hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("voice key stream"))
	hl.bind("J", hl.dsp.exec_cmd("voice lang ja"))
	hl.bind("E", hl.dsp.exec_cmd("voice lang en-dk"))
	hl.bind("D", hl.dsp.exec_cmd("voice lang da"))
	hl.bind("A", hl.dsp.exec_cmd("voice lang auto"))
	hl.bind("ESCAPE", hl.dsp.submap("reset"))
end)

hl.bind("SUPER + W", hl.dsp.exec_cmd("banditshell toggle wallpaper"))

hl.bind("CTRL + SHIFT + grave", hl.dsp.exec_cmd(terminal .. " btop"), { description = "Task manager" })

-- Keyboard cursor
for _, d in ipairs(directions) do
	hl.bind(
		"SUPER + CTRL + " .. d.key,
		hl.dsp.exec_cmd(string.format("ydotool mousemove -- %d %d", d.dx * cursor_step, d.dy * cursor_step)),
		{ repeating = true }
	)
end
hl.bind("SUPER + CTRL + SPACE", hl.dsp.exec_cmd("ydotool click 0xC0"))
hl.bind("SUPER + CTRL + ALT + SPACE", hl.dsp.exec_cmd("ydotool click 0xC1"))

-- Help: SUPER + ?
hl.bind("SUPER + SHIFT + Slash", hl.dsp.exec_cmd("banditshell toggle panel hotkeys"), { description = "Toggle hotkey sheet" })

-- Laptop
local function media_keys(tbl)
	for _, m in ipairs(tbl) do
		hl.bind(m[1], hl.dsp.exec_cmd(m[2]), { locked = true, repeating = m[3] })
	end
end

media_keys({
	{ "XF86AudioRaiseVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+", true },
	{ "XF86AudioLowerVolume", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", true },
	{ "XF86AudioMute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" },
	{ "XF86AudioMicMute", "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle" },
	{ "XF86MonBrightnessUp", "brightnessctl s 10%+", true },
	{ "XF86MonBrightnessDown", "brightnessctl s 10%-", true },
	{ "XF86AudioNext", "playerctl next" },
	{ "XF86AudioPause", "playerctl play-pause" },
	{ "XF86AudioPlay", "playerctl play-pause" },
	{ "XF86AudioPrev", "playerctl previous" },
})

hl.bind("SUPER + SHIFT + Z", hl.dsp.exec_cmd("banditshell toggle panel keyboard"))

-- Tablet hinge is an evdev switch, not a key.
local tablet_switch = "Lenovo Yoga Tablet Mode Control switch"
hl.bind("switch:on:" .. tablet_switch, hl.dsp.exec_cmd("banditshell set tablet on compositor"), { locked = true })
hl.bind("switch:off:" .. tablet_switch, hl.dsp.exec_cmd("banditshell set tablet off compositor"), { locked = true })

-- Output toggle, bound twice for numlock's two numpad-zero keysyms.
for _, key in ipairs({ "KP_0", "KP_Insert" }) do
	hl.bind("SUPER + " .. key, hl.dsp.exec_cmd("banditshell toggle output"))
end
