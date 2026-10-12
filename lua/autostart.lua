-- Everything runs inside hyprland.start so `--verify-config` stays side-effect free.

local host = require("lua.host")

hl.on("hyprland.start", function()
    -- One shell, chained: exec_cmd does not wait, and the portal must start
    -- after the dbus import or OBS capture goes black.
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
        .. " && systemctl --user start xdg-desktop-portal-hyprland")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")

    hl.dispatch(hl.dsp.focus({ workspace = 1 }))
    hl.exec_cmd("clipse -listen")

    -- The tray apps wait until banditshell is up. If it won't start, shell-up
    -- opens a rescue terminal on workspace 1 instead.
    hl.exec_cmd("~/.config/hypr/scripts/shell-up 'qbittorrent --no-splash' spotify")

    hl.exec_cmd("~/.local/bin/zen-pseudo-manager")
    hl.exec_cmd("udiskie")

    if host.is("banditbox") then
        hl.exec_cmd("~/Projects/diablo/deploy/tmux-start.sh")
    end
end)
