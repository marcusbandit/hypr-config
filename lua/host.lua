-- Host detection: one config, two machines (banditbox desktop, kangaeru
-- laptop), kept byte-identical and branching at runtime. Every module that
-- needs the hostname requires THIS file rather than sniffing for itself, so
-- the lookup happens once and a third machine has one place to go.

local M = {}

local function read_first_line(path)
    local handle = io.open(path, "r")
    if not handle then
        return nil
    end
    local line = handle:read("*l")
    handle:close()
    return line
end

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

-- /etc/hostname is the authority; $HOSTNAME is a shell variable and usually
-- not exported, so it is a backstop. "unknown" matches no host table, so an
-- unknown box gets the generic (preferred/auto, no GPU env) treatment.
M.name = clean(read_first_line("/etc/hostname"))
    or clean(os.getenv("HOSTNAME"))
    or "unknown"

function M.is(name)
    return M.name == name
end

return M
