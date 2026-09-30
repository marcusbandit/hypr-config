-- Environment variables. Everything below is live: the old env.conf had fifteen
-- `env = NAME=value` lines that hyprlang silently ignored (it wants
-- `env = NAME,value`). Unused candidates are kept commented out at the bottom.

local host = require("lua.host")

local home = os.getenv("HOME") or "/home/bandit"

hl.env("PATH", table.concat({
    home .. "/.local/bin",
    home .. "/bin",
    "/usr/local/bin",
    "/usr/bin",
    "/bin",
    "/usr/sbin",
    "/sbin",
}, ":")) -- hyprlang expanded $HOME; Lua does not

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct") -- env.conf set qt5ct then qt6ct; only the winner is ported
hl.env("XCURSOR_THEME", "Bibata-Modern-DodgerBlue")
hl.env("XCURSOR_SIZE", "24")
hl.env("TERMINAL", "foot")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- GPU, per host: a stale LIBVA_DRIVER_NAME=nvidia on the AMD laptop broke VAAPI
-- and silently forced ffmpeg onto the CPU fallback, so nothing is set on AMD
-- (mesa autodetects; unset is the safe default) and the NVIDIA block is gated.
if host.is("banditbox") then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")         -- VAAPI through nvidia's driver
    hl.env("GBM_BACKEND", "nvidia-drm")           -- buffer allocation via nvidia-drm
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia") -- libglvnd picks the nvidia GLX
    hl.env("NVD_BACKEND", "direct")               -- NVDEC direct backend

    -- GL driver keeps its hands off adaptive sync; the compositor drives VRR.
    -- Two layers owning VRR is what produces flicker. No conflict with vrr = 1
    -- in lua/monitors.lua.
    hl.env("__GL_VRR_ALLOWED", "0")
    hl.env("__GL_GSYNC_ALLOWED", "0")
end

-- Inert in the old config too; uncomment one at a time and relog.
-- hl.env("GTK_THEME", "Adwaita:dark")
-- hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- hl.env("QT_QUICK_CONTROLS_STYLE", "gtk")
-- hl.env("KDE_COLOR_SCHEME_PATH", "/usr/share/color-schemes/BreezeDark.colors")
-- hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
-- hl.env("_JAVA_OPTIONS", "-Dawt.useSystemAAFontSettings=on -Dswing.aatext=true -Dswing.defaultlaf=com.sun.java.swing.plaf.gtk.GTKLookAndFeel")

-- Dropped on purpose, all would be harmful or redundant:
--   XDG_RUNTIME_DIR=/tmp/hyprland  (real: /run/user/1000)
--   WAYLAND_DISPLAY=wayland-0      (Hyprland picks its own socket)
--   the remaining XDG_* lines      (session already sets them to these values)
