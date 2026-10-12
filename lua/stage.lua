-- The stage: a layout for streaming, registered as "lua:stage". The first
-- window is a 16:9 box at full height, centred; the rest alternate into the
-- columns beside it (right, then left), stacked top to bottom.
--
-- Fullscreen means the stage: a window whose app believes it is fullscreen
-- (client state, kept off the whole monitor by sync_fullscreen = false in
-- lua/rules.lua) takes the stage, and the stage window takes its slot. When
-- it leaves fullscreen, both go back. With several in fullscreen, the newest
-- holds the stage, as with real fullscreen.
--
-- The lock: Hyprland hands a Lua layout no resize deltas, a drag on a tiled
-- window only re-runs recalculate, so nothing can pull the stage out of 16:9.
-- Side windows get their height on keys instead (layout messages "taller"
-- and "shorter", bound in lua/binds.lua). Floating windows resize as usual.

local mode = require("lua.mode")

local M = {}

M.name = "lua:stage"

local RATIO = 16 / 9
local FULLSCREEN = 2 -- Hyprland's fullscreen mode value; 1 is maximized

-- Side window height weights by window address, 1 when unset. Reset by a
-- reload; a column then splits evenly again.
local weights = {}

-- The stage window per workspace id, as of the last layout pass. Putting a
-- window on stage swaps it with this one.
M.stage_of = {}

local function weight(target)
    local w = target.window
    return w and weights[w.address] or 1
end

local function stack(column, x, y, w, h)
    local total = 0
    for _, t in ipairs(column) do
        total = total + weight(t)
    end
    local top = y
    for i, t in ipairs(column) do
        -- The last one takes the remainder, so rounding never leaves a seam.
        local th = i == #column and (y + h - top) or math.floor(h * weight(t) / total)
        t:place({ x = x, y = top, w = w, h = th })
        top = top + th
    end
end

-- Per workspace id: windows in client fullscreen at the last pass, and the
-- one holding the stage. A window new to fullscreen takes the stage;
-- otherwise the holder keeps it.
local fs_last, fs_holder = {}, {}

-- A reload re-registers this layout, and Hyprland drops every client
-- fullscreen on its workspaces with it (built-in layouts keep theirs), so a
-- staged game would fall out of fullscreen. The set is kept in a file, holders
-- last so they are restored last and win the stage again.
local fs_file = mode.state_dir .. "/stage-fullscreen"
local fs_written = nil
local fs_restore = nil

local function read_lines(path)
    local f = io.open(path, "r")
    if not f then return {} end
    local lines = {}
    for line in f:lines() do
        if line ~= "" then table.insert(lines, line) end
    end
    f:close()
    return lines
end

local function save_fullscreen()
    if fs_restore then return end
    local lines = {}
    for ws, set in pairs(fs_last) do
        for addr in pairs(set) do
            if addr ~= fs_holder[ws] then table.insert(lines, addr) end
        end
        if fs_holder[ws] then table.insert(lines, fs_holder[ws]) end
    end
    local text = table.concat(lines, "\n")
    if text == fs_written then return end
    -- The directory is there: it holds the streamer flag.
    local f = io.open(fs_file, "w")
    if not f then return end
    f:write(text, "\n")
    f:close()
    fs_written = text
end

if mode.streamer then
    fs_restore = read_lines(fs_file)
else
    os.remove(fs_file)
end

-- After a reload Hyprland moves the workspaces back onto this layout in a
-- props refresh, not in the reload itself; restoring any earlier is undone.
-- A window not back on the stage yet waits for the next refresh, three at
-- most, so saving cannot stay switched off.
local fs_tries = 0

hl.on("config.props_refreshed", function()
    if not fs_restore then return end
    local live = {}
    for _, w in ipairs(hl.get_windows()) do
        live[w.address] = w
    end
    local pending = {}
    for _, addr in ipairs(fs_restore) do
        local w = live[addr]
        if w and w.layout and w.layout.name == M.name then
            if w.fullscreen_client ~= FULLSCREEN then
                hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = FULLSCREEN, action = "set", window = "address:" .. addr }))
            end
        elseif w then
            table.insert(pending, addr)
        end
    end
    fs_tries = fs_tries + 1
    fs_restore = (#pending > 0 and fs_tries < 3) and pending or nil
end)

local function fullscreen_pick(ws, targets)
    local now, pick = {}, nil
    for i, t in ipairs(targets) do
        local w = t.window
        -- X11 windows never get the stage this way; see lua/rules.lua.
        if w and not w.xwayland and w.fullscreen_client == FULLSCREEN then
            now[w.address] = i
            if not (fs_last[ws] or {})[w.address] then
                pick = i
            end
        end
    end
    pick = pick or now[fs_holder[ws] or ""]
    if not pick then
        for _, i in pairs(now) do
            pick = math.min(pick or i, i)
        end
    end
    fs_last[ws] = now
    fs_holder[ws] = pick and targets[pick].window.address or nil
    save_fullscreen()
    return pick
end

local function recalculate(ctx)
    local a = ctx.area
    local targets = {}
    for i, t in ipairs(ctx.targets) do
        targets[i] = t
    end
    if #targets == 0 then return end

    local w1 = targets[1].window
    local ws = w1 and w1.workspace and w1.workspace.id or 0
    local pick = fullscreen_pick(ws, targets)
    if pick then
        targets[1], targets[pick] = targets[pick], targets[1]
    end

    local first = targets[1].window
    if first and first.workspace then
        M.stage_of[first.workspace.id] = first.address
    end

    local sw = math.min(math.floor(a.h * RATIO), math.floor(a.w))
    local side = math.floor((a.w - sw) / 2)

    -- No room beside the stage (a monitor no wider than 16:9): one column.
    if side < 1 then
        stack(targets, a.x, a.y, a.w, a.h)
        return
    end

    targets[1]:place({ x = a.x + side, y = a.y, w = sw, h = a.h })

    local right, left = {}, {}
    for i = 2, #targets do
        table.insert(i % 2 == 0 and right or left, targets[i])
    end
    stack(left, a.x, a.y, side, a.h)
    stack(right, a.x + side + sw, a.y, a.w - side - sw, a.h)
end

local steps = { taller = 1.25, shorter = 0.8 }

-- Unknown messages and the stage itself are ignored, not refused: a refusal
-- is a config error, and that banner would sit on stream.
local function layout_msg(ctx, msg)
    local step = steps[msg]
    local active = hl.get_active_window()
    if not step or not active then return end

    for i, t in ipairs(ctx.targets) do
        local w = t.window
        if w and w.address == active.address then
            if i > 1 then
                weights[w.address] = math.max(0.25, math.min((weights[w.address] or 1) * step, 4))
            end
            return
        end
    end
end

hl.layout.register("stage", { recalculate = recalculate, layout_msg = layout_msg })

-- The focused window, if it is tiled on a stage.
function M.window()
    local w = hl.get_active_window()
    if not w or not w.workspace or not w.layout or w.layout.name ~= M.name then return nil end
    return w
end

-- Swap the focused window onto the stage; the window that was there takes its
-- place beside it. Focus stays on the window that moved.
function M.put_on_stage()
    local w = M.window()
    if not w then return end
    local current = M.stage_of[w.workspace.id]
    if current and current ~= w.address then
        hl.dispatch(hl.dsp.window.swap({ target = "address:" .. current }))
    end
end

-- Focus view: the app goes fullscreen inside the stage (client state only),
-- which puts it on stage at 16:9. An X11 window is only put on stage: told it
-- is fullscreen in a tile, Wine fights it (lua/rules.lua). Off the stage
-- layout it is the ordinary whole-monitor fullscreen.
function M.focus_view()
    local w = M.window()
    if w and w.xwayland then
        M.put_on_stage()
    elseif w then
        hl.dispatch(hl.dsp.window.fullscreen_state({ internal = 0, client = FULLSCREEN, action = "toggle" }))
    else
        hl.dispatch(hl.dsp.window.fullscreen({ mode = "fullscreen" }))
    end
end

-- Grow or shrink the focused side window inside its column.
function M.resize(msg)
    return function()
        if M.window() then
            hl.dispatch(hl.dsp.layout(msg))
        end
    end
end

return M
