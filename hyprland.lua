-- Hyprland config (Lua).
-- Verify: Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
-- (misses suppress_event typos and bad layer-rule match keys; both fail silently)

require("lua.env")
require("lua.look")
require("lua.input")
require("lua.monitors")
require("lua.rules")
require("lua.binds")
require("lua.autostart")
