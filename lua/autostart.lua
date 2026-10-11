-- Everything runs inside hyprland.start so `--verify-config` stays side-effect free.

local host = require("lua.host")

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    -- Must start after the dbus import or OBS capture goes black.
    hl.exec_cmd("systemctl --user start xdg-desktop-portal-hyprland")

    hl.exec_cmd("hyprctl dispatch workspace 1")
    hl.exec_cmd("clipse -listen")

    -- No-op if already up, so a reload never spawns a second shell.
    hl.exec_cmd("/home/bandit/bin/banditshell start")

    hl.exec_cmd("~/.local/bin/zen-pseudo-manager")
    hl.exec_cmd("udiskie")

    -- After banditshell so the tray host is registered first.
    hl.exec_cmd("qbittorrent --no-splash")
    hl.exec_cmd("spotify")

    if host.is("banditbox") then
        hl.exec_cmd("~/.local/bin/fleet-viewer-kiosk")
        hl.exec_cmd("~/Projects/diablo/deploy/tmux-start.sh")
    end
end)
