-- Monitors and workspace assignment, per host. The two machines share this
-- file byte for byte, so all physical setup lives in one table keyed by
-- hostname: a third machine is one more entry, and the arms cannot drift.
-- An entry may carry (all optional, default empty):
--   outputs    monitor lines, applied in order on top of the catch-all
--   overrides  per-workspace extras merged onto the band rule
--   specials   named special workspaces pinned to an output
-- A host with no entry gets the catch-all line and Hyprland's defaults.
-- Which output owns which workspaces lives in the MANAGED BY BANDITSHELL
-- section below, host-keyed for the same reason.

local host = require("lua.host")

local ultrawide     = "HDMI-A-1"
local vertical_side = "DP-1"

-- Scale 1 is a DECISION, not a leftover: 0.8 was tried on the monitor and
-- rejected. Do not "restore" it off the old commented-out .conf line.
local ultrawide_scale = 1

local hosts = {
    banditbox = {
        -- Monitor line fields: mode, position (x y), scale, transform
        -- (1 = 90deg, so the rotated panel occupies 1200x1920 of layout),
        -- bitdepth, vrr, cm.
        outputs = {
            -- Side monitor, on its end, anchored at the origin.
            { output = vertical_side, mode = "1920x1200@60", position = "0x0",
              scale = 1, transform = 1 },

            -- x = 1200 puts it right of the rotated panel; y = 240 roughly
            -- centre-aligns the pair.
            { output = ultrawide, mode = "5120x1440@144", position = "1200x240",
              scale = ultrawide_scale, transform = 0, bitdepth = 8, vrr = 1 },

            -- HDR mode for the same panel; SWAP it in rather than add it (two
            -- entries naming one output do not error, the later silently wins).
            -- { output = ultrawide, mode = "5120x1440@144", position = "1200x240",
            --   scale = 1, transform = 0, bitdepth = 10, vrr = 1,
            --   cm = "hdr", sdrbrightness = 1.2, sdrsaturation = 0.98 },
        },

        -- Workspace 6 stacks the scrolling layout downwards. Keys are the
        -- absolute workspace numbers the managed bands produce.
        overrides = {
            [6] = { layout = "scrolling", layout_opts = { direction = "down" } },
        },

        specials = {
            { workspace = "special:music", monitor = vertical_side },
        },
    },
}

local layout = hosts[host.name] or {}

--------------------------------------------------------------------------------
-- Outputs
--------------------------------------------------------------------------------

-- Empty output name = "any monitor no other line claims": the floor that keeps
-- an unknown box bootable, not an alternative to the per-host lines.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

for _, monitor in ipairs(layout.outputs or {}) do
    hl.monitor(monitor)
end

--------------------------------------------------------------------------------
-- Workspace assignment
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- >>> MANAGED BY BANDITSHELL >>>
--
-- The shell's to write; hand edits show up in its settings. Bands are
-- host-keyed; workspaces is a list, a range, or both: "1-6, 8-10".
--------------------------------------------------------------------------------

-- Spec text to workspace numbers; invalid in, nothing out.
local function bs_expand(spec)
    local out = {}
    for part in spec:gmatch("[^,]+") do
        -- The loop variable is a const local in Lua 5.4; the trimmed part is
        -- its own name.
        local p = part:match("^%s*(.-)%s*$")
        local a, b = p:match("^(%d+)%-(%d+)$")
        if a then
            a, b = tonumber(a), tonumber(b)
            if b < a or b - a > 512 then return {} end
            for ws = a, b do
                table.insert(out, ws)
            end
        else
            local n = p:match("^(%d+)$")
            if not n then return {} end
            table.insert(out, tonumber(n))
        end
    end
    return out
end

local bs_bands = {
    banditbox = {
        { monitor = ultrawide,     workspaces = "1-5" },
        { monitor = vertical_side, workspaces = "6-10" },
    },
}

-- <<< MANAGED BY BANDITSHELL <<<

-- Pinning a workspace to an output that does not exist quietly does nothing,
-- so a host with no bands gets no pinning rules at all.
local overrides = layout.overrides or {}

for _, band in ipairs(bs_bands[host.name] or {}) do
    for _, ws in ipairs(bs_expand(band.workspaces)) do
        local rule = { workspace = tostring(ws), monitor = band.monitor }
        for key, value in pairs(overrides[ws] or {}) do
            rule[key] = value
        end
        hl.workspace_rule(rule)
    end
end

for _, rule in ipairs(layout.specials or {}) do
    hl.workspace_rule(rule)
end
