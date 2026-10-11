local host = require("lua.host")

hl.config({
    input = {
        kb_layout  = "us,dk",
        kb_options = "caps:backspace, grp:switch",

        follow_mouse = 1,
        sensitivity  = 0,

        scroll_factor = 0.8,

        numlock_by_default  = true,
        special_fallthrough = true,

        touchpad = {
            natural_scroll = true,
        },
    },

    cursor = {
        no_hardware_cursors = true,
    },
})

-- Map the tablet to an aspect-correct centre slice of the ultrawide.
if host.is("banditbox") then
    local surface = { w = 224, h = 148 }   -- Intuos Pro M active area, mm
    local panel   = { w = 5120, h = 1440 } -- HDMI-A-1

    local region_w = math.floor(panel.h * surface.w / surface.h + 0.5)

    hl.device({
        name            = "wacom-intuos-pro-m-pen",
        output          = "HDMI-A-1",
        region_position = string.format("%d 0", math.floor((panel.w - region_w) / 2)),
        region_size     = string.format("%d %d", region_w, panel.h),
    })
end
