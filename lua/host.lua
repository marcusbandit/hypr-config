--------------------------------------------------------------------------------
-- HOST DETECTION
--
-- One config, two machines. banditbox is the desktop (NVIDIA RTX 3090, an
-- ultrawide plus a rotated side panel); kangaeru is the laptop (AMD Radeon 840M
-- iGPU, one built-in panel). Work happens in bursts on whichever box is in
-- front of me, so the two copies have to stay byte-identical and branch at
-- runtime. The alternative, a per-machine edit on top of a shared base, is how
-- a config quietly turns into two forks that nobody can merge again.
--
-- Every module that needs to know which box it is on requires THIS file rather
-- than sniffing the hostname for itself. Two reasons: `require` caches, so the
-- lookup happens exactly once per session no matter how many modules ask, and
-- there is exactly one place to teach about a third machine.
--
-- Where the name comes from, in order:
--
--   1. /etc/hostname. On Arch this is the authority (systemd reads it at boot
--      to set the kernel hostname) and it is a plain file, so it costs one
--      io.open with no process spawn. Preferring a file read over
--      io.popen("hostname") also keeps this working if Hyprland's embedded Lua
--      ever loses the ability to spawn.
--   2. $HOSTNAME, for the case where /etc/hostname is missing or unreadable.
--      Worth knowing: that is a bash/zsh shell variable and is usually NOT
--      exported, so it is very often empty inside a compositor's environment.
--      It is a backstop, not the main path.
--   3. "unknown". Deliberately a name no machine of mine has, so a host that
--      fails both lookups takes the fallback branch everywhere (preferred/auto
--      monitors, no GPU-specific env) instead of being mistaken for one of the
--      two known boxes. A generic session that boots beats a tailored one that
--      does not.
--
-- Nothing here calls into `hl`, so this module is safe to require from any
-- other one, including before the config has been applied.
--------------------------------------------------------------------------------

local M = {}

--- First line of a file, or nil if it cannot be opened.
--- "*l" rather than "l" so this reads the same under Lua 5.1/LuaJIT and 5.4;
--- the leading star is the older spelling and 5.4 still accepts it.
local function read_first_line(path)
    local handle = io.open(path, "r")
    if not handle then
        return nil
    end
    local line = handle:read("*l")
    handle:close()
    return line
end

--- Trim surrounding whitespace, collapsing "nothing useful" to nil.
--- /etc/hostname ends in a newline and an unset $HOSTNAME reads as an empty
--- string, so both have to fall through to the next source rather than becoming
--- a hostname of "" that matches no host table and no `is()` check.
local function clean(value)
    if not value then
        return nil
    end
    local trimmed = value:match("^%s*(.-)%s*$")
    if trimmed == "" then
        return nil
    end
    return trimmed
end

--- The hostname of the machine this config is running on. Resolved once, at
--- require time, and never re-read.
M.name = clean(read_first_line("/etc/hostname"))
    or clean(os.getenv("HOSTNAME"))
    or "unknown"

--- Sugar for the `if host.is("banditbox") then` branch, so callers are not
--- spelling out a comparison against `host.name` every time. Prefer a table
--- keyed by hostname (see lua/monitors.lua) when there is more than one value
--- to vary; this is for the genuinely binary case.
function M.is(name)
    return M.name == name
end

return M
