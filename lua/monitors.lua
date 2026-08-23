--------------------------------------------------------------------------------
-- MONITORS AND WORKSPACE ASSIGNMENT
--
-- Ported from the MONITOR CONFIGURATION block at the bottom of hyprland.conf
-- and the "WORKSPACE ASSIGNMENT TO MONITORS" block at the top of
-- hyprland/rules.conf. Those two lived in separate files but describe one
-- thing (which physical output owns what), so they are kept together here.
--
-- The output names are locals rather than repeated string literals: rules.conf
-- carried its own duplicate `$ultrawide` / `$vertical_side` pair with a comment
-- telling the reader to keep it in sync with hyprland.conf by hand. Defining
-- them once removes that chore.
--------------------------------------------------------------------------------

local host = require("lua.host")

local ultrawide     = "HDMI-A-1"
local vertical_side = "DP-1"

--------------------------------------------------------------------------------
-- Per-host layout
--
-- The two machines this config drives have nothing in common physically, and
-- the file is shared between them byte for byte, so everything describing a
-- physical setup lives in ONE table keyed by hostname. Deliberately a table
-- rather than an if/else chain with hardcoded calls in each arm: the branch is
-- data, so a third machine (or a third screen on this one) is one more entry
-- and none of the loops below change. There is also then no way for one arm to
-- drift out of step with another, which is exactly what happened to the
-- duplicated output names the header above talks about.
--
-- An entry may carry any of:
--
--   outputs    monitor lines, applied in order on top of the catch-all.
--   bands      contiguous runs of workspaces, one run per output.
--   overrides  per-workspace extras merged onto the generated band rule.
--   specials   named special workspaces pinned to an output.
--
-- All four are optional and all four default to empty, so a host with no entry
-- at all gets the catch-all monitor line and nothing else: no workspace
-- pinning, and Hyprland's own default (a workspace opens on whichever output
-- has focus) applies. That is the correct behaviour for a single-screen
-- machine, and it is what lets an unmodified checkout boot usefully on a box
-- this file has never heard of.
--
-- kangaeru has no entry on purpose. Its one built-in panel is already served
-- by the catch-all, and naming an output there would only create something to
-- get wrong the next time a kernel update renames eDP-1.
--------------------------------------------------------------------------------

-- Scale of the ultrawide, pulled out and named because it is the one number in
-- this file that actually gets retuned.
--
-- 1 is a DECISION, not a leftover, so do NOT "restore" 0.8 on the strength of
-- the old commented-out .conf line: nothing was lost. That line intended 0.8
-- (logical width 6400, everything on screen correspondingly smaller), but while
-- it sat commented out the session fell through to the catch-all below and ran
-- at 1 for months. Both were then put on the actual monitor and compared side
-- by side, and 1 is the one that was picked.
local ultrawide_scale = 1

local hosts = {
    banditbox = {
        -- The old hyprlang column header, kept as the map from the .conf form
        -- to these keys, because the positional form is what every other
        -- Hyprland example online still uses:
        --
        --   Monitor, Resolution@Hz, Pos, Scale, Rotation 1-3, Bitdepth n, VRR, Color mode
        --
        -- hyprlang took those positionally (with `transform` / `bitdepth` /
        -- `vrr` / `cm` as inline keywords); the Lua form names every field.
        outputs = {
            -- The side monitor, physically stood on its end. transform = 1 is
            -- the 90 degree rotation, so the panel occupies 1200x1920 on the
            -- layout even though its mode is 1920x1200. Anchored at the origin,
            -- which is what the ultrawide's offset below is measured against.
            { output = vertical_side, mode = "1920x1200@60", position = "0x0",
              scale = 1, transform = 1 },

            -- The ultrawide, default (SDR) mode. x = 1200 puts it immediately
            -- right of the rotated panel (1200 wide once rotated, see above),
            -- and y = 240 drops it so the two read as roughly centre-aligned
            -- rather than top-aligned.
            { output = ultrawide, mode = "5120x1440@144", position = "1200x240",
              scale = ultrawide_scale, transform = 0, bitdepth = 8, vrr = 1 },

            -- HDR mode for that same panel. SWAP it for the line above rather
            -- than adding it: two entries naming one output do not error, the
            -- later one just silently wins, which is a confusing way to find
            -- out. Note it carries its own scale on purpose.
            -- { output = ultrawide, mode = "5120x1440@144", position = "1200x240",
            --   scale = 1, transform = 0, bitdepth = 10, vrr = 1,
            --   cm = "hdr", sdrbrightness = 1.2, sdrsaturation = 0.98 },
        },

        -- rules.conf spelled out ten near-identical `workspace = N, monitor:...`
        -- lines. The actual rule is far smaller: contiguous bands, one band per
        -- output. Declaring the bounds and generating the run means moving the
        -- split (or adding an eleventh workspace) is a one-number edit instead
        -- of a rewrite, and two bands can never silently overlap.
        bands = {
            { monitor = ultrawide,     first = 1, last = 5 },
            { monitor = vertical_side, first = 6, last = 10 },
        },

        -- Per-workspace extras merged on top of the generated band rule.
        -- Workspace 6 is the vertical panel's landing spot, so it runs the
        -- scrolling layout stacked downwards rather than sideways. It is the
        -- only workspace that deviates, and keeping it beside the bands rather
        -- than inside them keeps the common case readable.
        overrides = {
            [6] = { layout = "scrolling", layout_opts = { direction = "down" } },
        },

        specials = {
            { workspace = "special:music", monitor = vertical_side },
        },
    },
}

-- This machine's entry, or an empty one. Resolving the unknown-host case once
-- here means the loops below just read fields off `layout` and each field's own
-- `or {}` handles a host that declares some sections but not others.
local layout = hosts[host.name] or {}

--------------------------------------------------------------------------------
-- Outputs
--------------------------------------------------------------------------------

-- The catch-all, and it runs on every host including the named ones. An empty
-- output name in Hyprland means "any monitor no other line claims", so this is
-- the floor the per-host lines stand on, not an alternative to them: it brings
-- anything unrecognised up at its preferred mode, auto-placed, unscaled. On a
-- host with no entry it is also the ONLY monitor line, which is what keeps a
-- brand new machine bootable instead of coming up to a black screen.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Then this host's specifics, in declaration order, on top of that floor.
for _, monitor in ipairs(layout.outputs or {}) do
    hl.monitor(monitor)
end

--------------------------------------------------------------------------------
-- Workspace assignment to monitors
--
-- Generated from the bands above, and host-gated for the same reason the
-- outputs are. Pinning a workspace to an output that does not exist is not a
-- parse error, it just quietly does nothing useful, so on a single-screen
-- laptop the right answer is no pinning at all rather than pinning ten
-- workspaces at two monitors that are not plugged in. A host with no `bands`
-- therefore emits no workspace rules and gets Hyprland's default behaviour.
--------------------------------------------------------------------------------

local overrides = layout.overrides or {}

for _, band in ipairs(layout.bands or {}) do
    for ws = band.first, band.last do
        local rule = { workspace = tostring(ws), monitor = band.monitor }
        for key, value in pairs(overrides[ws] or {}) do
            rule[key] = value
        end
        hl.workspace_rule(rule)
    end
end

-- Special workspaces. Same story: pinned only where the output exists.
for _, rule in ipairs(layout.specials or {}) do
    hl.workspace_rule(rule)
end
