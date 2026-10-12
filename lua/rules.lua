local theme = require("lua.theme")
local mode = require("lua.mode")
local stage = require("lua.monitors").stage

local popup_width  = 880
local popup_height = 652

-- A rule beats decoration.rounding, so bare has to zero the rules too.
local window_rounding = mode.bare and 0 or theme.rounding.window

-- Global
hl.window_rule({
    name           = "global-suppress-maximize",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fullscreen video or a game holds off the idle lock (hypridle.conf).
hl.window_rule({
    name         = "global-idle-inhibit-fullscreen",
    match        = { class = ".*" },
    idle_inhibit = "fullscreen",
})

-- The emulator's phone body keeps the bezel radius; everything else is
-- demoted (per-window rounding rules cap at 20, the global does not).
hl.window_rule({
    name     = "global-rounding",
    match    = { class = "negative:^(Emulator)$" },
    rounding = window_rounding,
})

-- Borders: two-colour string form only; the table form breaks inactive.
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

-- Utility windows
hl.window_rule({
    name         = "clipse-popup",
    match        = { class = "clipse" },
    float        = true,
    size         = { popup_width, popup_height },
    stay_focused = true,
})

-- scripts/shell-up opens this when banditshell won't start at login.
hl.window_rule({
    name      = "banditshell-rescue",
    match     = { class = "^(banditshell-rescue)$" },
    workspace = "1",
})

hl.window_rule({
    name   = "regionpick",
    match  = { title = "^(regionpick)$" },
    float  = true,
    center = true,
    pin    = true,
})

-- Android emulator: floating, centred phone bezel; the toolbar is demoted.
hl.window_rule({
    name   = "android-emulator",
    match  = { class = "^(Emulator)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name     = "android-emulator-toolbar",
    match    = { class = "^(Emulator)$", title = "negative:^(Android Emulator).*" },
    rounding = window_rounding,
})

-- Workspaces
hl.window_rule({ name = "zen-browser-workspace", match = { class = "^(zen)$" }, workspace = "1" })
hl.window_rule({ name = "cursor-ide-workspace",  match = { class = "^(cursor)$" }, workspace = "2" })
hl.window_rule({ name = "diablo-dashboard",      match = { class = "^(diablo)$" }, workspace = "6" })
hl.window_rule({ name = "hytale-launcher",       match = { class = "^(Hytale-launcher)$" }, workspace = "2", center = true })
hl.window_rule({ name = "steam-client-workspace", match = { class = "^(steam)$" }, workspace = "2" })
hl.window_rule({ name = "steam-games-workspace", match = { class = "^(steam_app.*)$" }, workspace = "3" })

-- Media
hl.window_rule({
    name        = "mpv-borderless",
    match       = { class = "^(mpv)$" },
    border_size = 0,
    rounding    = 0,
})

hl.window_rule({
    name    = "spotify-opacity",
    match   = { class = "^([Ss]potify)$" },
    opacity = "0.9 override",
})

hl.window_rule({
    name      = "spotify-workspace",
    match     = { class = "^([Ss]potify)$" },
    workspace = "special:music silent",
})

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

-- Streamer mode: OBS opens on the side panel, off the stage. "obs" under
-- XWayland, the desktop id under Wayland.
if mode.streamer then
    hl.window_rule({
        name      = "streamer-obs-workspace",
        match     = { class = "^(obs|com\\.obsproject\\.Studio)$" },
        workspace = "7",
    })
end

-- Streamer mode, on the stage's workspaces (lua/stage.lua): an app asking for
-- fullscreen only believes it got it, so it stays tiled and the stage layout
-- gives it the 16:9 stage instead of the whole ultrawide.
if mode.streamer and stage then
    hl.window_rule({
        name            = "streamer-stage-fullscreen",
        match           = { workspace = "m[" .. stage .. "]s[0]" },
        sync_fullscreen = false,
    })

    -- Not for X11 (Proton games): told it is fullscreen in a 16:9 tile, Wine
    -- sees a window smaller than the monitor and drops and re-asks fullscreen
    -- several times a second. Their requests are ignored instead; set games
    -- to windowed or borderless. Applied when a window opens.
    hl.window_rule({
        name           = "streamer-x11-no-fullscreen",
        match          = { xwayland = true },
        suppress_event = "fullscreen",
    })

    -- Games open on workspace 3. They hold off the idle lock themselves:
    -- Hyprland's fullscreen inhibit only counts whole-monitor fullscreen.
    local games = {
        { content = "game" },
        { class = "^steam_app_.*$" },
        { class = "^Minecraft.*" },
        { class = "^sober$" },
    }
    for i, match in ipairs(games) do
        hl.window_rule({
            name             = "streamer-game-" .. i,
            match            = match,
            workspace    = "3",
            idle_inhibit = "always",
        })
    end
end

-- Games
hl.window_rule({
    name   = "sober-no-blur",
    match  = { class = "^(sober)$" },
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

hl.window_rule({
    name  = "fl-studio-tile",
    match = { class = "^(fl64.exe)$" },
    tile  = true,
})

-- gvoice dictation host: a real Chrome window that must stay mapped (a
-- throttled renderer stops transcribing), hidden the 1x1-transparent way.
-- It parks in the bottom-right corner of the rightmost monitor: one
-- monitor's own corner, so the point is always on a screen. Width and height
-- are the mode's, so rotated and scaled outputs are converted first.
local function layout_corner(margin)
    local x, y = 1920 - margin, 1080 - margin -- fallback: monitors not up yet
    local ok, monitors = pcall(hl.get_monitors)
    if ok and type(monitors) == "table" then
        local right = -math.huge
        for _, mon in ipairs(monitors) do
            local w, h = mon.width / mon.scale, mon.height / mon.scale
            if mon.transform % 2 == 1 then
                w, h = h, w
            end
            if mon.x + w > right then
                right = mon.x + w
                x, y = right - margin, mon.y + h - margin
            end
        end
    end
    return math.floor(x) .. " " .. math.floor(y)
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
        max_size         = { 1, 1 },
        move             = layout_corner(2),
        no_blur          = true,
        float            = true,
    })
end

-- Custom apps
hl.window_rule({
    name         = "ollama-dmenu-float",
    match        = { class = "^(com.bandit.OllamaDmenuApp)$" },
    float        = true,
    center       = true,
    border_size  = 0,
    stay_focused = true,
})

-- Dialogs
hl.window_rule({ name = "open-file-dialog",   match = { title = "^(Open File)$" }, float = true })
hl.window_rule({ name = "save-file-dialog",   match = { title = "^(Save File)$" }, float = true })
hl.window_rule({ name = "file-chooser-dialog", match = { title = "^(.*[Ff]ile [Cc]hooser.*)$" }, float = true })

-- Layers: namespace is the only match key a layer rule honours.
hl.layer_rule({
    name         = "banditshell-frosted-chassis",
    match        = { namespace = "banditshell" },
    blur         = true,
    xray         = false,
    ignore_alpha = 0.05,
})
