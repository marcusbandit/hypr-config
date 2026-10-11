local theme = require("lua.theme")

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
        enabled = true,
    },

    scrolling = {
        focus_fit_method = 1,
    },

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

-- The Lua binding hard-caps borderangle speed at 100 (deciseconds); the
-- intended 50s period runs as 10s.
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "linear", style = "loop" })

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
