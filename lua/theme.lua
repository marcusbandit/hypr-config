-- Palette: generated from the theme system, greensteel as fallback.
local M = {}

local GENERATED = "/.config/theme/current/hypr-colors.lua"

-- A generated palette missing any stop is rejected whole, never half-applied.
local REQUIRED = {
    "abyss", "body", "border_lit", "brass", "brass_dim", "dark",
    "lush", "mint", "mint_dim", "shadow", "verdigris", "white",
}

local fallback_hex = {
    void    = "070C0A",
    abyss   = "0D1512",
    dark    = "16211C",
    plate   = "1B2A23",
    body    = "22322B",
    brushed = "33493F",
    edge    = "4C6B5C",
    lit     = "6E9384",
    pale    = "9DBDAF",
    silver  = "C9E2D7",
    chrome  = "EAF6F0",
    white   = "F7FDFA",

    verdigris = "3FBF8F",
    lush      = "5FD99A",
    phosphor  = "8CFFC0",

    mint      = "5FF2C4",
    mint_dim  = "1E6B57",
    brass     = "D8C48C",
    brass_dim = "6B5C36",

    border_lit = "3A4F46",
    shadow     = "040907",
}

-- loadfile + pcall: a broken generated file must cost a colour, not a session.
local function load_generated()
    local home = os.getenv("HOME")
    if not home then return nil end

    local chunk = loadfile(home .. GENERATED)
    if not chunk then return nil end

    local ok, palette = pcall(chunk)
    if not ok or type(palette) ~= "table" then return nil end

    for _, name in ipairs(REQUIRED) do
        if type(palette[name]) ~= "string" then return nil end
    end

    return palette
end

M.hex = load_generated() or fallback_hex

local function alpha_hex(a)
    if type(a) == "string" then return a end
    return string.format("%02x", math.floor(a * 255 + 0.5))
end

function M.rgb(name)
    local hex = M.hex[name] or error("unknown palette stop: " .. tostring(name), 2)
    return "rgb(" .. hex .. ")"
end

function M.rgba(name, a)
    local hex = M.hex[name] or error("unknown palette stop: " .. tostring(name), 2)
    return "rgba(" .. hex .. alpha_hex(a) .. ")"
end

M.border_active = {
    colors = {
        M.rgba("dark", "ff"),
        M.rgba("verdigris", "ff"),
    },
    angle = 45,
}

M.border_inactive = "rgba(00000000)"
M.shadow = M.rgba("shadow", "ee")

-- decoration.rounding is the emulator bezel; per-window rules cap at 20, the
-- global does not, so `window` is applied per-rule and `bezel` globally.
M.rounding = {
    window = 15,
    bezel  = 30,
}

M.floating = { active = M.rgb("mint"), inactive = "rgba(00000000)" }
M.pinned   = { active = M.rgb("brass"), inactive = "rgba(00000000)" }

return M
