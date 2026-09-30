-- Input settings, ported from the input/gestures/cursor blocks of
-- hyprland/general.conf. hyprlang's nested blocks map straight onto nested
-- tables in hl.config.

local host = require("lua.host")

hl.config({
    input = {
        kb_layout  = "us,dk",
        kb_variant = "",
        kb_model   = "",
        -- One string, not a list: the comma is part of the XKB value.
        -- Caps Lock becomes Backspace; grp:switch flips layouts.
        kb_options = "caps:backspace, grp:switch",
        kb_rules   = "",

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

-- Tablet mapping. A tablet is absolute: on the whole ultrawide a circle draws
-- 2.35x too wide, so map it to a slice of the panel carrying the tablet's own
-- aspect. Width is computed, not hardcoded, so a panel or tablet change cannot
-- silently break it.
if host.is("banditbox") then
    local surface = { w = 224, h = 148 }   -- Intuos Pro M active area, mm
    local panel   = { w = 5120, h = 1440 } -- HDMI-A-1

    local region_w = math.floor(panel.h * surface.w / surface.h + 0.5)

    hl.device({
        name            = "wacom-intuos-pro-m-pen",
        output          = "HDMI-A-1",
        region_position = string.format("%d 0", math.floor((panel.w - region_w) / 2)), -- centred
        region_size     = string.format("%d %d", region_w, panel.h),
    })
end
