-- Host detection: one config, two machines, branching at runtime.
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

M.name = clean(read_first_line("/etc/hostname"))
    or clean(os.getenv("HOSTNAME"))
    or "unknown"

function M.is(name)
    return M.name == name
end

return M
