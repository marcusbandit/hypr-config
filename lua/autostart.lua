--------------------------------------------------------------------------------
-- AUTOSTART APPLICATIONS
--
-- Ported from hyprland/exec.conf. Every `exec-once` line is inside the
-- `hyprland.start` callback, in the original order, and the order is load
-- bearing: dbus activation environment first, then polkit, then the shell.
--
-- Why the callback and not bare `hl.exec_cmd` calls at file scope: a top-level
-- `hl.exec_cmd` runs for real during `Hyprland --verify-config`, so a config
-- check would silently start a second shell, a second clipboard listener and
-- so on. `hl.on("hyprland.start", ...)` does not fire during verification, so
-- checking the config stays free of side effects. Nothing may be lifted out of
-- this function.
--
-- Not carried over from exec.conf, and not by accident:
--
--   launch-caelestia          caelestia is not the shell anymore, banditshell
--                             is. Starting both races two shells for the same
--                             layer surfaces.
--   awww-daemon --format xrgb wallpaper daemon belonging to that old shell.
--   hypr-game-caps-watcher    not wanted.
--
-- This list is host-independent on purpose: everything below runs on both
-- machines, so there is nothing here for lua/host.lua to branch on.
--------------------------------------------------------------------------------

hl.on("hyprland.start", function()
    -- Set up DBus activation environment first so everything that follows gets a complete environment
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Auth agent (start early so any app that needs auth doesn't block)
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- Set initial workspace before the shell renders the bar (avoids wrong workspace indicator flash)
    hl.exec_cmd("hyprctl dispatch workspace 1")

    -- Clipboard manager
    hl.exec_cmd("clipse -listen")

    -- Shell (starts after dbus + polkit are ready, so it has a complete environment).
    -- banditshell is the shell now; caelestia is no longer started. `start` is a no-op
    -- if a qs is already up, so a reload here never spawns a second shell.
    hl.exec_cmd("/home/bandit/bin/banditshell start")

    -- Misc background services
    -- hyprlang expanded the leading `~`; Lua does not, and hl.exec_cmd runs the
    -- string through /bin/sh, so the shell expands it instead.
    hl.exec_cmd("~/.local/bin/zen-pseudo-manager")
    hl.exec_cmd("udiskie")

    -- qBittorrent. Started after banditshell so the tray host (services/Tray.qml)
    -- is already registered as the SNI watcher when Qt looks for it.
    --
    -- Comes up with no window at all: General\StartMinimized in
    -- ~/.config/qBittorrent/qBittorrent.conf sends it straight to the tray.
    -- That setting lives in qBittorrent's own config rather than here because
    -- there is no CLI flag for it, and a window rule cannot express it either
    -- (a rule can only place a window that exists). When the tray icon or
    -- SUPER+T does bring the window up, rules.lua parks it on
    -- special:torrents. NOTE: qBittorrent rewrites qBittorrent.conf on exit,
    -- so edit that file only while it is stopped.
    hl.exec_cmd("qbittorrent --no-splash")

    -- Music. rules.lua parks spotify on the special:music workspace and
    -- monitors.lua pins that workspace to the vertical side panel, so this
    -- comes up out of the way and SUPER+tab pulls it into view. Last in the
    -- list because nothing else waits on it.
    hl.exec_cmd("spotify")
end)
