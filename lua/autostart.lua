-- Autostart. Everything inside hyprland.start: a bare hl.exec_cmd at file scope
-- really runs during `Hyprland --verify-config`, and the callback does not, so
-- a config check stays free of side effects. Nothing may be lifted out.

local host = require("lua.host")

hl.on("hyprland.start", function()
    -- dbus env first, then polkit, then the shell; the order is load-bearing.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- The portal manager can be dbus-activated before the import above lands,
    -- and ConditionEnvironment=WAYLAND_DISPLAY is only checked at start time, so
    -- the Hyprland portal gets skipped and screen capture in OBS goes black.
    -- `start` is a no-op if it is already up; after the import the condition passes.
    hl.exec_cmd("systemctl --user start xdg-desktop-portal-hyprland")

    hl.exec_cmd("hyprctl dispatch workspace 1") -- before the bar renders

    hl.exec_cmd("clipse -listen")

    -- `start` is a no-op if a qs is already up, so a reload never spawns a second shell.
    hl.exec_cmd("/home/bandit/bin/banditshell start")

    -- hyprlang expanded the leading `~`; the shell does it instead.
    hl.exec_cmd("~/.local/bin/zen-pseudo-manager")
    hl.exec_cmd("udiskie")

    -- After banditshell so the tray host is registered before Qt looks for it.
    -- Starts minimised to the tray (qBittorrent.conf; it rewrites that file on
    -- exit, edit it only while stopped). rules.lua parks it on special:torrents.
    hl.exec_cmd("qbittorrent --no-splash")

    -- Last; nothing waits on it. Parked on special:music.
    hl.exec_cmd("spotify")

    if host.is("banditbox") then
        hl.exec_cmd("~/.local/bin/fleet-viewer-kiosk") -- dashboard kiosk on ws 6
        hl.exec_cmd("~/Projects/diablo/deploy/tmux-start.sh") -- windows/panes in his session, never new sessions
    end
end)
