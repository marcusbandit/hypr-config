-- Window and layer rules. Reference: https://wiki.hypr.land/Configuring/Window-Rules/
-- Colours come from lua/theme.lua so a stop is defined exactly once.

local theme = require("lua.theme")

-- Shared sizes: change once, every popup follows.
local popup_width           = 880
local popup_height          = 652
local dialog_width          = 800
local dialog_height         = 600

-- Unused, kept so a terminal float rule can come back.
local terminal_float_width  = 1350
local terminal_float_height = 900

--------------------------------------------------------------------------------
-- GLOBAL RULES
--------------------------------------------------------------------------------

-- suppress_event values are validated at runtime, not at parse time, so
-- --verify-config accepts typos here silently.
hl.window_rule({
    name           = "global-suppress-maximize",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Global rounding is the emulator bezel (per-window rules cap at 20, the global
-- is uncapped; see lua/theme.lua), so demote everything else back down.
-- "negative:" is Hyprland's match inversion (RE2 has no lookahead) and also
-- passes unclassed windows.
hl.window_rule({
    name     = "global-rounding",
    match    = { class = "negative:^(Emulator)$" },
    rounding = theme.rounding.window,
})

--------------------------------------------------------------------------------
-- BORDERS
--------------------------------------------------------------------------------

-- Two-colour string form is the ONLY correct one: the table form makes Hyprland
-- read a two-stop gradient on the ACTIVE border and leave inactive unset.
-- Floating - mint, pinned - brass (palette in lua/theme.lua).
hl.window_rule({
    name         = "floating-border",
    match        = { float = true, pin = false },
    border_color = theme.floating.active .. " " .. theme.floating.inactive,
})

hl.window_rule({
    name         = "pinned-border",
    match        = { pin = true },
    border_color = theme.pinned.active .. " " .. theme.pinned.inactive,
})

--------------------------------------------------------------------------------
-- TERMINAL & UTILITY WINDOWS
--------------------------------------------------------------------------------

hl.window_rule({
    name         = "clipse-popup",
    match        = { class = "clipse" },
    float        = true,
    size         = { popup_width, popup_height },
    stay_focused = true,
})

hl.window_rule({
    name   = "auto-update-terminal",
    match  = { class = "auto-update" },
    float  = true,
    size   = { dialog_width, dialog_height },
    center = true,
})

-- regionpick: its own program, a picker window for OBS capture. Match on the
-- title: the toolkit's class is generic (org.quickshell).
hl.window_rule({
    name   = "regionpick",
    match  = { title = "^(regionpick)$" },
    float  = true,
    center = true,
})

-- Android Emulator (Jet Lag dev) - floating, centred, phone bezel.
-- Fixed number, NOT derived from the window rounding: a bezel is the phone's
-- property. No rounding rule on the body on purpose (falls through to the
-- global theme.rounding.bezel; a rule here could only go smaller).
-- Class only: covers the phone body and its side-toolbar.
hl.window_rule({
    name   = "android-emulator",
    match  = { class = "^(Emulator)$" },
    float  = true,
    center = true,
})

-- The ~61px toolbar under the same class; invert the BODY's title so anything
-- else the emulator spawns is demoted by default.
hl.window_rule({
    name     = "android-emulator-toolbar",
    match    = { class = "^(Emulator)$", title = "negative:^(Android Emulator).*" },
    rounding = theme.rounding.window,
})

--------------------------------------------------------------------------------
-- BROWSER RULES
--------------------------------------------------------------------------------

hl.window_rule({
    name      = "zen-browser-workspace",
    match     = { class = "^(zen)$" },
    workspace = "1",
})

-- Kiosk profile only (class is "firefox"); the daily browser is zen.
hl.window_rule({
    name      = "fleet-viewer-kiosk",
    match     = { class = "^(firefox)$" },
    workspace = "6",
})

hl.window_rule({
    name      = "diablo-dashboard",
    match     = { class = "^(diablo)$" },
    workspace = "6",
})

--------------------------------------------------------------------------------
-- DEVELOPMENT TOOLS
--------------------------------------------------------------------------------

hl.window_rule({
    name      = "cursor-ide-workspace",
    match     = { class = "^(cursor)$" },
    workspace = "2",
})

--------------------------------------------------------------------------------
-- MEDIA & ENTERTAINMENT
--------------------------------------------------------------------------------

hl.window_rule({
    name        = "mpv-borderless",
    match       = { class = "^(mpv)$" },
    border_size = 0,
    rounding    = 0,
})

-- Class is "Spotify", capital S. Both cases matched so a rename upstream
-- cannot silently unmatch the rules again.
hl.window_rule({
    name    = "spotify-opacity",
    match   = { class = "^([Ss]potify)$" },
    opacity = "0.9 override",
})

-- "silent" is a suffix on the workspace VALUE, not a rule field; keeps the
-- special workspace from popping open over boot.
hl.window_rule({
    name      = "spotify-workspace",
    match     = { class = "^([Ss]potify)$" },
    workspace = "special:music silent",
})

-- Class is the reverse-DNS app id, not "qbittorrent"; window only exists once
-- the tray icon or SUPER+T brings it up.
hl.window_rule({
    name      = "qbittorrent-workspace",
    match     = { class = "^(org\\.qbittorrent\\.qBittorrent)$" },
    workspace = "special:torrents silent",
})

hl.window_rule({
    name      = "vesktop-workspace",
    match     = { class = "^(vesktop)$" },
    workspace = "special:communication",
})

--------------------------------------------------------------------------------
-- ANDROID (WAYDROID)
--------------------------------------------------------------------------------

hl.window_rule({
    name   = "waydroid-float",
    match  = { class = "^(Waydroid)$" },
    float  = true,
    size   = { 675, 1350 },
    center = true,
})

--------------------------------------------------------------------------------
-- GAMING
--------------------------------------------------------------------------------

hl.window_rule({
    name      = "hytale-launcher",
    match     = { class = "^(Hytale-launcher)$" },
    workspace = "2",
    center    = true,
})

hl.window_rule({
    name      = "steam-games-workspace",
    match     = { class = "^(steam_app.*)$" },
    workspace = "3",
})

hl.window_rule({
    name     = "sober-no-blur",
    match    = { class = "^(sober)$" },
    no_blur  = true,
    rounding = 0,
})

hl.window_rule({
    name   = "minecraft-layout",
    match  = { class = "^Minecraft.*" },
    tile   = true,
    pseudo = true,
    size   = { 3440, 1440 },
})

--------------------------------------------------------------------------------
-- AUDIO PRODUCTION
--------------------------------------------------------------------------------

hl.window_rule({
    name  = "fl-studio-tile",
    match = { class = "^(fl64.exe)$" },
    tile  = true,
})

--------------------------------------------------------------------------------
-- SYSTEM UTILITIES
--------------------------------------------------------------------------------

hl.window_rule({
    name             = "xwayland-videobridge-hide",
    match            = { class = "^(xwaylandvideobridge)$" },
    opacity          = "0.0 override",
    no_anim          = true,
    no_initial_focus = true,
    max_size         = { 1, 1 },
    no_blur          = true,
})

-- gvoice dictation host: a real Chrome window (Google's speech engine is only
-- reachable from a browser). Must stay MAPPED: Chrome throttles renderers it
-- thinks are not visible and a throttled renderer stops transcribing. Hidden
-- the xwaylandvideobridge way instead: transparent, 1x1, off in a corner -
-- not fully offscreen, so frame callbacks keep flowing.
-- Matched on CLASS only: Chrome ignores --class under Wayland and builds the
-- app_id from the URL ("chrome-<host>_<path>-<profile>"; the daemon uses the
-- invented hostname gvoice.localhost so the class is not shared with every
-- other localhost app). Title is useless: at map time it is still the raw URL.
-- The IP form is the fallback for boxes where *.localhost does not resolve.

-- move takes plain numbers; hyprlang's "100%-2" percentage form silently lands
-- the window at 0,0 here, so compute the corner off the real outputs.
local function layout_corner(margin)
    local x, y = 1920 - margin, 1080 - margin -- fallback: monitors not up yet
    local ok, monitors = pcall(hl.get_monitors)
    if ok and type(monitors) == "table" and #monitors > 0 then
        x, y = 0, 0
        for _, mon in ipairs(monitors) do
            x = math.max(x, mon.x + mon.width - margin)
            y = math.max(y, mon.y + mon.height - margin)
        end
    end
    return x .. " " .. y
end

for _, m in ipairs({
    { name = "gvoice-hide",    match = { class = "^chrome-gvoice\\.localhost.*$" } },
    { name = "gvoice-hide-ip", match = { class = "^chrome-127\\.0\\.0\\.1__.*-Default$" } },
}) do
    hl.window_rule({
        name             = m.name,
        match            = m.match,
        opacity          = "0.0 override",
        no_anim          = true,
        no_initial_focus = true,
        no_focus         = true,
        -- Chrome refuses to shrink below ~61x57, so keep the transparent window
        -- off in the bottom-right corner where it is no click-trap.
        max_size         = { 1, 1 },
        move             = layout_corner(2),
        no_blur          = true,
        float            = true,
    })
end

--------------------------------------------------------------------------------
-- CUSTOM APPLICATIONS
--------------------------------------------------------------------------------

hl.window_rule({
    name         = "ollama-dmenu-float",
    match        = { class = "^(com.bandit.OllamaDmenuApp)$" },
    float        = true,
    center       = true,
    border_size  = 0,
    stay_focused = true,
    idle_inhibit = "fullscreen",
})

--------------------------------------------------------------------------------
-- DIALOG WINDOWS
--------------------------------------------------------------------------------

hl.window_rule({
    name  = "open-file-dialog",
    match = { title = "^(Open File)$" },
    float = true,
})

hl.window_rule({
    name  = "save-file-dialog",
    match = { title = "^(Save File)$" },
    float = true,
})

hl.window_rule({
    name  = "file-chooser-dialog",
    match = { title = "^(.*[Ff]ile [Cc]hooser.*)$" },
    float = true,
})

--------------------------------------------------------------------------------
-- LAYER RULES
--------------------------------------------------------------------------------

-- namespace is the ONLY match key a layer rule honours; anything else parses
-- and then silently never matches.
hl.layer_rule({
    name         = "banditshell-frosted-chassis",
    match        = { namespace = "banditshell" },
    blur         = true,
    xray         = false,
    ignore_alpha = 0.05,
})
