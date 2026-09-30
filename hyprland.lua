-- Hyprland config (Lua). Rollback: rename this file, relog (the choice is made
-- at startup, a reload is not enough). Check without logging out:
--   Hyprland --verify-config -c ~/.config/hypr/hyprland.lua
-- That catches syntax/key/rule errors but NOT suppress_event typos or bad
-- layer-rule match keys; both fail silently.

require("lua.env")        -- first, so everything spawned later inherits it
require("lua.look")       -- appearance
require("lua.input")      -- input devices and cursor
require("lua.monitors")   -- outputs and workspace bands
require("lua.rules")      -- window and layer rules
-- lua.columncap (the 3-column cap) is gone: the scrolling tape is uncapped
-- again. Restore with `git checkout -- lua/columncap.lua` + this line back.
require("lua.binds")      -- keybinds and submaps
require("lua.autostart")  -- last, runs against a fully applied config
require("lua.demo")
