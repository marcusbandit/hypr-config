-- Look and feel, ported from hyprland/general.conf (general/decoration/
-- animations/scrolling/master/misc). No hex here; colours come from lua/theme.lua.

local theme = require("lua.theme")

-- gaps_in applies per window side, so the tiled seam is 2 * gap and the screen
-- edge is gaps_out; both derive from one number.
local gap = 5

hl.config({
    general = {
        gaps_in  = gap,
        gaps_out = gap * 2,

        border_size = 2,

        col = {
            active_border   = theme.border_active,
            inactive_border = theme.border_inactive,
        },

        resize_on_border = false,
        allow_tearing    = false,

        layout = "scrolling",
    },

    decoration = {
        -- G2 squircle corners: rounding_power 4.0 makes curvature go to 0 at
        -- the edge; radius is bumped since a superellipse bites less off the
        -- diagonal at the same r.
        --
        -- NOT the window radius: this is the emulator bezel, and the
        -- global-rounding rule in lua/rules.lua demotes everything else.
        -- Reasoning next to the numbers in lua/theme.lua.
        rounding       = theme.rounding.bezel,
        rounding_power = 4.0,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        dim_special = 0.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = theme.shadow,
        },

        blur = {
            enabled  = true,
            size     = 8,
            passes   = 2,
            vibrancy = 0.1696,
            xray     = true,
            popups   = true,
        },
    },

    animations = {
        enabled = true, -- hyprlang's joke value "yes, please :)" parsed as true
    },

    scrolling = {
        focus_fit_method = 1,
    },

    -- Default (1) resizes the whole split chain, reflowing sibling windows --
    -- upstream calls that intended (issues #12553/#12367/#12380, closed
    -- not-planned). 0 is the pre-0.52 semantic: only the grabbed split moves.
    dwindle = {
        smart_resizing = 0,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}   } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}   } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}      } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}    } })
hl.curve("easeOutExpo",    { type = "bezier", points = { {0.19, 1},    {0.22, 1}   } })

hl.animation({ leaf = "global", enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })

-- Rotates the gradient so the highlight travels the border; speed is
-- deciseconds per rotation. PORTING LOSS: the binding hard-caps speed at 100
-- (CLuaConfigFloat(0, 0, 100) in LuaBindingsConfigRules.cpp), anything above
-- is a hard config error, so 500 (50s per rotation) runs as 100 (10s). Set
-- enabled = false for the static highlight.
local BORDERANGLE_PERIOD  = 500 -- deciseconds per rotation, the intended value
local BORDERANGLE_LUA_MAX = 100 -- hard cap in the Lua binding
hl.animation({
    leaf    = "borderangle",
    enabled = true,
    speed   = math.min(BORDERANGLE_PERIOD, BORDERANGLE_LUA_MAX),
    bezier  = "linear",
    style   = "loop",
})

hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutExpo",  style = "slide" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 4.5,  bezier = "easeOutExpo",  style = "slidevert" })
