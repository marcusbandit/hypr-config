-- Palette. NOT defined here: ~/.config/theme/current/hypr-colors.lua is
-- generated from the theme system (edit the theme's colors.toml, never the
-- generated file) and loaded below, with greensteel as the fallback for a
-- fresh machine. The ramp is a luminance ramp with a specular spike, one hue
-- family climbing from near-black to white; a theme swaps the hue but must
-- not flatten the ramp or the gradients stop reading as lit metal.
-- Monocraft (pixel font) needs the bright accent or silver on abyss/void;
-- mid-tones make mush on 1px stems.

local M = {}

local GENERATED = "/.config/theme/current/hypr-colors.lua"

-- A generated palette missing any stop is rejected whole, never half-applied.
local REQUIRED = {
    "abyss", "body", "border_lit", "brass", "brass_dim", "dark",
    "lush", "mint", "mint_dim", "shadow", "verdigris", "white",
}

-- FALLBACK ONLY (greensteel). Cool anodised green, one hue family around 158deg.
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

-- loadfile + pcall rather than dofile: dofile raises and would abort the whole
-- config load, leaving a broken session instead of a mis-coloured one.
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

--------------------------------------------------------------------------------
-- Derived gradients
--------------------------------------------------------------------------------

M.border_active = {
    colors = {
        M.rgba("dark", "ff"),
        M.rgba("verdigris", "ff"),
    },
    angle = 45,
}

M.border_inactive = "rgba(00000000)"

M.shadow = M.rgba("shadow", "ee")

--------------------------------------------------------------------------------
-- Corner radii
--------------------------------------------------------------------------------

-- READ BEFORE TOUCHING decoration.rounding (set in lua/look.lua). The global
-- is `bezel`, not `window`, and lua/rules.lua pulls everything but the
-- emulator's phone body back down to `window`. Inverted on purpose: Hyprland
-- 0.56.2 caps the per-window rounding RULE at 20
--   {"rounding", ... new CLuaConfigInt(0, 0, 20) ...}
--   (LuaBindingsInternal.hpp)
-- while the global is uncapped, so a radius above 20 is reachable only as the
-- global. Re-check with:
--   grep -n '"rounding"' /usr/include/hyprland/src/config/lua/bindings/LuaBindingsInternal.hpp
M.rounding = {
    window = 15, -- every ordinary window
    bezel  = 30, -- the emulator's phone body; independent of `window`
}

-- Different metals: mint floating, brass pinned.
M.floating = { active = M.rgb("mint"), inactive = "rgba(00000000)" }
M.pinned   = { active = M.rgb("brass"), inactive = "rgba(00000000)" }

return M
