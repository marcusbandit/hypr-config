-- The stage: the default layout, and streamer mode's on the ultrawide,
-- registered as "lua:stage". The first window is a 16:9 box at full height,
-- centred; the rest stack top to bottom in the columns beside it.
--
-- The columns: each side window keeps the column it was put in. A new window
-- opens in the column that had focus. Opened from the stage, it takes an
-- empty column, else the left one. SUPER+SHIFT+LEFT/RIGHT carries a side
-- window across, and never touches the stage; the window leaving the stage
-- takes over the column of the one that replaced it.
--
-- The lock: Hyprland hands a Lua layout no resize deltas, a drag on a tiled
-- window only re-runs recalculate, so nothing can pull the stage out of 16:9.
-- Side windows get their height on keys instead (layout messages "taller"
-- and "shorter", bound in lua/binds.lua). Floating windows resize as usual.

local M = {}

M.name = "lua:stage"

local RATIO = 16 / 9

-- Side window height weights by window address, 1 when unset. Reset by a
-- reload; a column then splits evenly again.
local weights = {}

-- Side window columns by window address: { ws = workspace id, side =
-- "left"|"right" }. An entry from another workspace counts as unset, so a
-- window moved here is placed like a new one.
local sides = {}

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

local function side_of(t)
    local w = t.window
    local e = w and sides[w.address]
    if e and w.workspace and e.ws == w.workspace.id then return e.side end
end

local function set_side(t, side)
    local w = t.window
    if w and w.workspace then
        sides[w.address] = { ws = w.workspace.id, side = side }
    end
end

-- Give every side window without a column one.
local function assign(targets, ws, prev_stage)
    local first_pass = prev_stage == nil
    local new, count = {}, { left = 0, right = 0 }
    for i = 2, #targets do
        local t = targets[i]
        local side = side_of(t)
        local w = t.window
        if not side and w and w.address == prev_stage and targets[1].window then
            -- Demoted off the stage: it takes the newcomer's old column.
            side = side_of(targets[1]) or "left"
            set_side(t, side)
        elseif not side and first_pass then
            -- A reload forgot the columns: deal them out as before.
            side = i % 2 == 0 and "right" or "left"
            set_side(t, side)
        end
        if side then
            count[side] = count[side] + 1
        else
            table.insert(new, t)
        end
    end
    if #new == 0 then return end

    -- The window focused before the newcomer: lowest focus history among
    -- the ones already placed (the newcomer itself usually holds 0).
    local is_new = {}
    for _, t in ipairs(new) do is_new[t] = true end
    local before, best
    for i, t in ipairs(targets) do
        local w = t.window
        if not is_new[t] and w and (not best or w.focus_history_id < best) then
            before, best = i, w.focus_history_id
        end
    end

    for _, t in ipairs(new) do
        local side
        if before and before > 1 then
            side = side_of(targets[before]) or "left"
        elseif count.left > 0 and count.right == 0 then
            side = "right"
        else
            side = "left"
        end
        set_side(t, side)
        count[side] = count[side] + 1
    end
end

local function recalculate(ctx)
    local a, targets = ctx.area, ctx.targets
    if #targets == 0 then return end

    local first = targets[1].window
    local ws = first and first.workspace and first.workspace.id
    if ws then
        assign(targets, ws, M.stage_of[ws])
        M.stage_of[ws] = first.address
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
        table.insert(side_of(targets[i]) == "right" and right or left, targets[i])
    end
    stack(left, a.x, a.y, side, a.h)
    stack(right, a.x + side + sw, a.y, a.w - side - sw, a.h)
end

local steps = { taller = 1.25, shorter = 0.8 }

-- Unknown messages and the stage itself are ignored, not refused: a refusal
-- is a config error, and that banner would sit on stream.
local function layout_msg(ctx, msg)
    local step = steps[msg]
    local to = msg:match("^side (%a+)$")
    local active = hl.get_active_window()
    if not (step or to == "left" or to == "right") or not active then return end

    for i, t in ipairs(ctx.targets) do
        local w = t.window
        if w and w.address == active.address then
            if i > 1 and to then
                set_side(t, to)
            elseif i > 1 then
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

-- SUPER+SHIFT+direction. On a stage, LEFT/RIGHT carry a side window into the
-- other column and leave the stage window where it is; pointing outward from
-- a column, and every other case, is the stock move (onto another monitor).
function M.move(dir)
    return function()
        local w = M.window()
        if w and (dir == "left" or dir == "right") then
            local current = M.stage_of[w.workspace.id]
            if current == w.address then return end
            local e = sides[w.address]
            if e and e.side ~= dir then
                hl.dispatch(hl.dsp.layout("side " .. dir))
                return
            end
        end
        hl.dispatch(hl.dsp.window.move({ direction = dir }))
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
