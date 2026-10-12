-- Session modes, read once per load: every module that changes with a mode
-- requires this, so a reload re-derives everything from the flags. Flip them
-- with scripts/hypr-mode, never with a live hl.config.
--   bare      banditshell's edge.bare: no chrome, no gaps, no rounding.
--   streamer  hypr-mode's state file: bare plus the 16:9 stage.

local M = {}

local home = os.getenv("HOME") or "/home/bandit"
local config = os.getenv("XDG_CONFIG_HOME") or (home .. "/.config")
local state = os.getenv("XDG_STATE_HOME") or (home .. "/.local/state")

M.state_dir = state .. "/hypr"

-- scripts/hypr-mode builds the same path.
M.streamer_file = M.state_dir .. "/streamer"

local function read(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local text = f:read("*a")
    f:close()
    return text
end

-- edge.bare only: a "bare" key anywhere else in the shell's config must not
-- turn the compositor bare.
local function shell_bare()
    local text = read(config .. "/banditshell/config.json")
    local edge = text and text:match('"edge"%s*:%s*(%b{})')
    return edge ~= nil and edge:match('"bare"%s*:%s*true') ~= nil
end

M.streamer = read(M.streamer_file) ~= nil

-- Streamer implies bare, even before the shell has saved edge.bare.
M.bare = M.streamer or shell_bare()

return M
