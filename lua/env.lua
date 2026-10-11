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
}, ":"))

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XCURSOR_THEME", "Bibata-Modern-DodgerBlue")
hl.env("XCURSOR_SIZE", "24")
hl.env("TERMINAL", "foot")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- GPU env, per host: unset on AMD (mesa autodetects), gated on NVIDIA.
if host.is("banditbox") then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("GBM_BACKEND", "nvidia-drm")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
    hl.env("NVD_BACKEND", "direct")
    -- Driver must not touch VRR; the compositor owns it (vrr = 1 in monitors.lua).
    hl.env("__GL_VRR_ALLOWED", "0")
    hl.env("__GL_GSYNC_ALLOWED", "0")
end
