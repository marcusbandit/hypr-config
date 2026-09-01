--------------------------------------------------------------------------------
-- INPUT SETTINGS
--
-- Ported from the `input {}`, `gestures {}` and `cursor {}` blocks of
-- hyprland/general.conf. Everything else in that file (general, decoration,
-- animations, scrolling, master, misc) is ported elsewhere.
--
-- hyprlang's nested blocks map straight onto nested tables in `hl.config`, so
-- `input:touchpad:natural_scroll` is just `input.touchpad.natural_scroll` here.
--------------------------------------------------------------------------------

local host = require("lua.host")

hl.config({
    input = {
        -- Two layouts, US primary and Danish secondary; `grp:switch` below is
        -- what flips between them.
        kb_layout  = "us,dk",
        kb_variant = "",
        kb_model   = "",
        -- One string, not a list: XKB itself takes a comma-separated option
        -- string, so the comma is part of the value. Caps Lock becomes
        -- Backspace, and the layout group switches on the configured key.
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

--------------------------------------------------------------------------------
-- Gestures
--
-- general.conf declared an empty `gestures {}` block, so there is nothing to
-- port: no gesture was ever configured. Left as this note rather than an
-- invented `hl.gesture` call, so the absence stays deliberate and visible.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- TABLET MAPPING
--
-- A tablet is an ABSOLUTE device: its surface maps corner-to-corner onto
-- whatever it is pointed at. Pointed at the whole ultrawide that means a
-- 224x148mm surface stretched across 5120x1440, so a circle drawn on the tablet
-- comes out 2.35x too wide on screen and the pen crosses a metre of glass for a
-- centimetre of movement. Mapping it to a slice of the panel that carries the
-- tablet's OWN aspect fixes both.
--
-- The width is computed rather than written down: hardcoding 2179 means the
-- mapping silently goes wrong the day the panel or the tablet changes.
--
-- On Wayland there is no xsetwacom and OpenTabletDriver does not do Bluetooth,
-- so the compositor is the only thing that can do this.
--------------------------------------------------------------------------------

if host.is("banditbox") then
    local surface = { w = 224, h = 148 }   -- Intuos Pro M active area, mm
    local panel   = { w = 5120, h = 1440 } -- HDMI-A-1

    local region_w = math.floor(panel.h * surface.w / surface.h + 0.5)

    hl.device({
        name            = "wacom-intuos-pro-m-pen",
        output          = "HDMI-A-1",
        -- Centred horizontally, full panel height. Relative to the output's
        -- own top-left, not the global layout origin.
        region_position = string.format("%d 0", math.floor((panel.w - region_w) / 2)),
        region_size     = string.format("%d %d", region_w, panel.h),
    })
end
