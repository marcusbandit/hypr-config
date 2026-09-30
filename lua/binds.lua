-- Bind variant mapping: binde -> { repeating = true }  bindl -> { locked = true }
-- bindel -> both  bindm -> { mouse = true }  bindd -> { description = "..." }

local terminal    = "foot"
local browser     = "zen-browser"
local filemanager = "yazi"

-- Drives layout focus, window movement, and the keyboard cursor.
local directions = {
    { key = "LEFT",  msg = "l", name = "left",  dx = -1, dy =  0 },
    { key = "RIGHT", msg = "r", name = "right", dx =  1, dy =  0 },
    { key = "UP",    msg = "u", name = "up",    dx =  0, dy = -1 },
    { key = "DOWN",  msg = "d", name = "down",  dx =  0, dy =  1 },
}

local workspace_count = 10 -- workspaces 1..N, bound to the digit row
local cursor_step     = 20 -- pixels per ydotool mousemove step


-- #! Viewport

-- Layout-specific binds, swapped live by hypr-layout-toggle through
-- apply_layout_binds() below. Scrolling gets the scrolling layout's own
-- geometry (layoutmsg); anything else gets stock Hyprland behavior (core
-- movefocus, no promote/swapcol/fit — default dwindle has none of those).
-- Parse-time default matches look.lua: scrolling.
local function bind_scrolling()
    for _, d in ipairs(directions) do
        hl.bind("SUPER + " .. d.key, hl.dsp.layout("focus " .. d.msg), { repeating = true })
    end

    hl.bind("SUPER + SHIFT + RETURN",          hl.dsp.layout("promote"))
    hl.bind("SUPER + SHIFT + CONTROL + RIGHT", hl.dsp.layout("swapcol r"))
    hl.bind("SUPER + SHIFT + CONTROL + LEFT",  hl.dsp.layout("swapcol l"))
    hl.bind("SUPER + F",                       hl.dsp.layout("fit active"))
    hl.bind("SUPER + SHIFT + F",               hl.dsp.layout("fit visible"))
end

local function bind_plain()
    for _, d in ipairs(directions) do
        hl.bind("SUPER + " .. d.key, hl.dsp.focus({ direction = d.name }), { repeating = true })
    end
end

local function unbind_scrolling()
    for _, d in ipairs(directions) do
        hl.unbind("SUPER + " .. d.key)
    end
    hl.unbind("SUPER + SHIFT + RETURN")
    hl.unbind("SUPER + SHIFT + CONTROL + RIGHT")
    hl.unbind("SUPER + SHIFT + CONTROL + LEFT")
    hl.unbind("SUPER + F")
    hl.unbind("SUPER + SHIFT + F")
end

function apply_layout_binds(name)
    unbind_scrolling()
    if name == "scrolling" then
        bind_scrolling()
    else
        bind_plain()
    end
end

apply_layout_binds("scrolling")

-- Flip general:layout between scrolling and dwindle, live. Script, not
-- dispatch: the config is lua, so the value goes through hyprctl eval
-- hl.config. Workspace 6 keeps its pinned scrolling rule either way.
hl.bind("SUPER + O", hl.dsp.exec_cmd("hypr-layout-toggle"), { description = "Toggle scrolling/dwindle layout" })

-- 1..9 map to their own digit, 10 sits on "0", hence `i % workspace_count`.
for i = 1, workspace_count do
    hl.bind("SUPER + " .. tostring(i % workspace_count), hl.dsp.focus({ workspace = i }))
end

hl.bind("SUPER + grave", hl.dsp.workspace.toggle_special("communication"))
hl.bind("SUPER + tab",   hl.dsp.workspace.toggle_special("music"))
-- SUPER+SHIFT+T is the screenshot OCR bind, so torrents' move-window bind uses ALT.
hl.bind("SUPER + T",     hl.dsp.workspace.toggle_special("torrents"))


-- #! Window

-- State
hl.bind("SUPER + A",         hl.dsp.window.fullscreen({ mode = "fullscreen" })) -- Fullscreen
hl.bind("SUPER + SHIFT + A", hl.dsp.exec_cmd("uxtrace record toggle --keys"), { description = "uxtrace: start or stop a recording for an agent" }) -- Record for an agent
hl.bind("SUPER + D",         hl.dsp.window.pseudo())                            -- Pseudo-tile
hl.bind("SUPER + G",         hl.dsp.window.pin())                               -- Global: persists across workspaces
hl.bind("SUPER + Q",         hl.dsp.window.close())                             -- Kill the hovered window
hl.bind("SUPER + S",         hl.dsp.window.float({ action = "toggle" }))        -- Toggle floating
-- SUPER+F / SUPER+SHIFT+F (fit active/visible) are scrolling-layout binds,
-- registered in bind_scrolling() above; stock dwindle has no fit.

-- 16:9 the focused window, full height, centered, ratio locked to corner
-- drags. A script (hypr-16x9(1)) so the same geometry is callable from
-- anywhere.
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("hypr-16x9"), { description = "Toggle locked 16:9 fit for the focused window" })
-- Portrait twin for the ultrawide: full height, width = height * 8/9.
hl.bind("SUPER + SHIFT + CONTROL + D", hl.dsp.exec_cmd("hypr-16x9 -r 8:9"), { description = "Toggle locked 8:9 fit for the focused window" })

-- Layout
for _, d in ipairs(directions) do
    hl.bind("SUPER + SHIFT + " .. d.key, hl.dsp.window.move({ direction = d.name }), { repeating = true })
end

-- Swap trades the two windows whole: position, column, and size travel with
-- the exchange, unlike move, which shuffles the others along.
for _, d in ipairs(directions) do
    hl.bind("SUPER + ALT + " .. d.key, hl.dsp.window.swap({ direction = d.name }), { repeating = true })
end

-- promote/swapcol are scrolling-layout binds, in bind_scrolling() above.

for i = 1, workspace_count do
    hl.bind("SUPER + SHIFT + " .. tostring(i % workspace_count), hl.dsp.window.move({ workspace = i }))
end

hl.bind("SUPER + SHIFT + grave", hl.dsp.window.move({ workspace = "special:communication" }))
hl.bind("SUPER + SHIFT + tab",   hl.dsp.window.move({ workspace = "special:music" }))
hl.bind("SUPER + ALT + T",       hl.dsp.window.move({ workspace = "special:torrents" }))

-- Move / Resize with mouse
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + X",         hl.dsp.window.drag(),   { mouse = true })
hl.bind("SUPER + SHIFT + X", hl.dsp.window.resize(), { mouse = true })


-- #! Apps

hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("banditshell launcher toggle"))

-- The calculator fell back to SUPER+Z when the sidebar toggle took SUPER+K.
-- Same calculator fullscreen on SUPER+ALT+K.
hl.bind("SUPER + Z", hl.dsp.exec_cmd("banditshell calculator toggle")) -- calculator panel
hl.bind("SUPER + ALT + K", hl.dsp.exec_cmd("banditshell calculator app"))
hl.bind("XF86Calculator", hl.dsp.exec_cmd("banditshell calculator toggle"), { locked = true })

hl.bind("SUPER + M", hl.dsp.exec_cmd("banditshell media toggle")) -- media card, keyboard-driven while up

-- The old .conf had `exec, [pseudeo; size 3440 1440;] $browser`: typo'd rule
-- (inert all along) plus a banditbox-only size, so it is not ported.
hl.bind("SUPER + B", hl.dsp.exec_cmd(browser))
hl.bind("SUPER + SHIFT + B", hl.dsp.exec_cmd(browser .. " --private-window"))
-- banditshell's own file browser, not yazi in a terminal.
-- Was: hl.dsp.exec_cmd(terminal .. " -e " .. filemanager)
hl.bind("SUPER + E",         hl.dsp.exec_cmd("banditshell files toggle"))
hl.bind("SUPER + RETURN",    hl.dsp.exec_cmd(terminal))

-- Copilot key is remapped to a plain Super modifier by keyd; no bind here.


-- #! Utils

-- Shell
hl.bind("SUPER + P", hl.dsp.exec_cmd("banditshell session toggle")) -- Toggle Power Menu
hl.bind("SUPER + L", hl.dsp.exec_cmd("loginctl lock-session"))      -- Lock the session

-- Rescue: several banditshell surfaces grab the keyboard exclusively and mask
-- clicks, so a dead one can leave the desktop looking frozen. This closes them.
hl.bind("SUPER + SHIFT + ESCAPE", hl.dsp.exec_cmd("banditshell close"))

-- The sidebar is banditshell's own now, hideable per monitor, so the bar
-- toggle has something to talk to again. It lives on SUPER+K (the calculator
-- panel's old seat; the calculator fell back to SUPER+Z). The other two are
-- still the to-build list; SUPER+SHIFT+D is taken now, a future dashboard
-- needs a key.
-- hl.bind("SUPER + N",         hl.dsp.exec_cmd("caelestia shell drawers toggle sidebar"))   -- Toggle Notification panel
-- hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("caelestia shell drawers toggle dashboard")) -- Toggle Dashboard
hl.bind("SUPER + K",          hl.dsp.exec_cmd("banditshell sidebar toggle"))               -- Toggle Sidebar

-- BARE: one key, two halves, ONE authority. The chrome's flag (edge.bare in
-- banditshell's config.json) is the single state of the pair; the compositor's
-- numbers NEVER vote and are never toggled on their own observation - they are
-- driven to match the flag, so a drifted pair converges on the next press
-- instead of flipping over together and staying inverted forever. The flag is
-- read here (io.open, a file read - no process spawn on the compositor's
-- loop), and the shell's on/off verbs are idempotent, so each press SETS both
-- halves to where the flag says they go. A number already in place is left
-- alone: worn gaps going bare are re-zeroed only if one of them is actually
-- worn, and the way back is always hyprctl reload, which returns look.lua's
-- truth to every window at once whatever drifted. If the flag is unreadable
-- the press does nothing: a half-applied pair beats an inverted one.
local function border_bare()
    local cfg = (os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config") .. "/banditshell/config.json"
    local f = io.open(cfg, "r")
    if not f then return nil end
    local text = f:read("*a")
    f:close()
    if text:match('"bare"%s*:%s*true') then return true end
    if text:match('"bare"%s*:%s*false') then return false end
    return nil
end

hl.bind("SUPER + SHIFT + K", function()
    local bare = border_bare()
    if bare == nil then
        print("border: could not read edge.bare - halves would drift on a guess, doing nothing")
        return
    end
    if bare then
        hl.exec_cmd("banditshell border on")
        hl.exec_cmd("hyprctl reload")
    else
        hl.exec_cmd("banditshell border off")
        local worn = (hl.get_config("general:gaps_out") or 0) ~= 0
                  or (hl.get_config("decoration:rounding") or 0) ~= 0
        if worn then
            hl.config({ general = { gaps_out = 0, gaps_in = 0 }, decoration = { rounding = 0 } })
        end
    end
end) -- Bare: chrome and gaps follow ONE flag - always converges, never inverts

-- Clipboard
hl.bind("SUPER + J",      hl.dsp.exec_cmd("~/.local/bin/ollama-clipboard"))                                -- Send Clipboard to Ollama
hl.bind("SUPER + V",      hl.dsp.exec_cmd("banditshell clipboard toggle"))                                 -- Clipboard history
hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd("env TYPE_CLIPBOARD_DEBUG=1 /home/bandit/.local/bin/type-clipboard")) -- Type clipboard

-- Long brackets: the command carries its own double quotes.
hl.bind("SUPER + SHIFT + T", hl.dsp.exec_cmd(
    [[grim -g "$(slurp $SLURP_ARGS)" "/tmp/ocr_image.png" && tesseract "/tmp/ocr_image.png" stdout -l eng | wl-copy && rm "/tmp/ocr_image.png"]]
))

hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("banditshell picker freezeclip")) -- Take screenshot

hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a --format=hex")) -- Color Picker

-- Region cam: pin a screen region as the capture. regionpick pops the overlay
-- picker (click a window or drag a rectangle) and crops the monitor capture in
-- OBS to that rectangle, so the capture follows the POSITION, not the window:
-- whatever sits at that spot later is what streams.
hl.bind("SUPER + ALT + C",         hl.dsp.exec_cmd("regionpick"),       { description = "Region cam: pick a region" })
hl.bind("SUPER + ALT + SHIFT + C", hl.dsp.exec_cmd("regionpick clear"), { description = "Region cam: reset to the full monitor" })

-- Dictation: tap to start, tap again to stop and type. No length cap; the
-- shell's pill shows the phases and the language. `voice key` keeps the voice
-- submap below in step with the recording.
hl.bind("SUPER + R", hl.dsp.exec_cmd("voice key")) -- Dictate: tap on, tap off
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("voice key stream")) -- Dictate: streaming

-- Live only while a recording runs (`voice key` enters/leaves the submap).
-- Pins are sticky; A hands back to auto-detect; ESC leaves without stopping.
hl.define_submap("voice", function()
    hl.bind("SUPER + R",       hl.dsp.exec_cmd("voice key"))        -- stop dictating, leave
    hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd("voice key stream")) -- stop streaming, leave
    hl.bind("J",         hl.dsp.exec_cmd("voice lang ja"))    -- Japanese
    hl.bind("E",         hl.dsp.exec_cmd("voice lang en-dk")) -- English, DK accent
    hl.bind("D",         hl.dsp.exec_cmd("voice lang da"))    -- Danish
    hl.bind("A",         hl.dsp.exec_cmd("voice lang auto"))  -- auto-detect
    hl.bind("ESCAPE",    hl.dsp.submap("reset"))
end)

-- Replay the last transcription into the focused window; refused while recording.
hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("voice retype")) -- Retype last dictation

-- Wallpaper is banditshell's own surface now; swww is not running.
-- hl.bind("SUPER + W", hl.dsp.exec_cmd("~/.local/bin/swww-random")) -- if swww comes back
hl.bind("SUPER + W",         hl.dsp.exec_cmd("banditshell wallpaper toggle")) -- Wallpaper on/off

-- Long brackets again: three quoted arguments, one with && inside.
hl.bind("CTRL + SHIFT + grave", hl.dsp.exec_cmd(
    [[~/.config/hypr/hyprland/scripts/launch_first_available.sh "gnome-system-monitor" "plasma-systemmonitor --page-name Processes" "command -v btop && foot -e fish -c btop"]]
))

-- Keyboard cursor, deltas from the direction table times the step.
for _, d in ipairs(directions) do
    hl.bind(
        "SUPER + CTRL + " .. d.key,
        hl.dsp.exec_cmd(string.format("ydotool mousemove -- %d %d", d.dx * cursor_step, d.dy * cursor_step)),
        { repeating = true }
    )
end

hl.bind("SUPER + CTRL + SPACE",         hl.dsp.exec_cmd("ydotool click 0xC0"))
hl.bind("SUPER + CTRL + ALT_L + SPACE", hl.dsp.exec_cmd("ydotool click 0xC1"))

-- Quickshell
hl.bind("SUPER + Slash", hl.dsp.global("quickshell:cheatsheetToggle"), { description = "Toggle cheatsheet" })
-- `?` is SHIFT + slash on the US half of kb_layout "us,dk".
hl.bind("SUPER + SHIFT + Slash", hl.dsp.exec_cmd("banditshell hotkeys toggle"), { description = "Toggle the hotkey sheet" })

hl.bind("SUPER + F4", hl.dsp.exit()) -- Exit Hyprland immediately


-- #! Laptop

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),  { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })

-- Brightness
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

-- Hinge is an evdev SWITCH, not a key; the shell can only hear about it through
-- these binds. Name is what `hyprctl devices` prints under Switches.
local tablet_switch = "Lenovo Yoga Tablet Mode Control switch"
hl.bind("switch:on:" .. tablet_switch,  hl.dsp.exec_cmd("banditshell tablet on compositor"),  { locked = true })
hl.bind("switch:off:" .. tablet_switch, hl.dsp.exec_cmd("banditshell tablet off compositor"), { locked = true })

hl.bind("SUPER + SHIFT + Z", hl.dsp.exec_cmd("banditshell keyboard toggle")) -- On-screen keyboard

-- Media
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


-- Sound

-- Speakers <-> headphones. Which two devices is a banditshell setting, per host.
-- Bound twice: numlock makes the numpad zero KP_0 or KP_Insert, and Hyprland
-- matches on the resolved keysym.
for _, key in ipairs({ "KP_0", "KP_Insert" }) do
    hl.bind("SUPER + " .. key, hl.dsp.exec_cmd("banditshell output toggle"))
end
