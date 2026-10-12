-- Monitors and workspace bands, per host. Both machines share this file;
-- a third machine is one more table entry.
--
-- >>> MANAGED BY BANDITSHELL >>>  (the shell's to write; hand edits show up
-- in its settings)

local host = require("lua.host")
local mode = require("lua.mode")
local stage_layout = require("lua.stage") -- registered before the rules name it

local ultrawide     = "HDMI-A-1"
local vertical_side = "DP-1"

local hosts = {
    banditbox = {
        outputs = {
            { output = vertical_side, mode = "1920x1200@60", position = "0x0",
              scale = 1, transform = 1 },
            { output = ultrawide, mode = "5120x1440@144", position = "1200x240",
              scale = 1, transform = 0, bitdepth = 8, vrr = 1 },
        },

        overrides = {
            [6] = { layout = "scrolling", layout_opts = { direction = "down" } },
        },

        specials = {
            { workspace = "special:music", monitor = vertical_side },
        },
    },
}

local layout = hosts[host.name] or {}

-- Catch-all so an unknown box stays bootable.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

for _, monitor in ipairs(layout.outputs or {}) do
    hl.monitor(monitor)
end

-- Spec text ("1-6, 8-10") to workspace numbers; invalid in, nothing out.
local function bs_expand(spec)
    local out = {}
    for part in spec:gmatch("[^,]+") do
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

local overrides = layout.overrides or {}

-- The output streamer mode stages on, per host. Outside the managed block so
-- the shell's rewrites leave it alone.
local stage = ({ banditbox = ultrawide })[host.name]

-- Streamer mode re-lays every band, after the overrides so it wins: the stage
-- output gets the 16:9 stage (lua/stage.lua), the rest stack downward.
local function streamer_layout(monitor)
    if not mode.streamer then return {} end
    if monitor == stage then
        return { layout = stage_layout.name }
    end
    return { layout = "scrolling", layout_opts = { direction = "down" } }
end

for _, band in ipairs(bs_bands[host.name] or {}) do
    for _, ws in ipairs(bs_expand(band.workspaces)) do
        local rule = { workspace = tostring(ws), monitor = band.monitor }
        for key, value in pairs(overrides[ws] or {}) do
            rule[key] = value
        end
        for key, value in pairs(streamer_layout(band.monitor)) do
            rule[key] = value
        end
        hl.workspace_rule(rule)
    end
end

for _, rule in ipairs(layout.specials or {}) do
    hl.workspace_rule(rule)
end

if stage then
    hl.env("HYPR_STAGE", stage) -- for scripts/hypr-mode aim
end

return { stage = stage }
