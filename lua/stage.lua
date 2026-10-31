-- The stage: the default layout, and streamer mode's on the ultrawide,
-- registered as "lua:stage". One window is a 16:9 box at full height,
-- centred; the rest stack top to bottom in the columns beside it.
--
-- The columns: each side window keeps the column and the spot it was put in.
-- A new window opens at the bottom of the column that had focus. Opened from
-- the stage, it takes an empty column, else the left one. A window dropped
-- after a mouse drag lands where the cursor let go: in a column at that
-- height, or on the stage. SUPER+SHIFT+LEFT/RIGHT carries a side window
-- across, UP/DOWN moves it inside its column, and neither touches the stage.
-- Whenever a window takes the stage, the one leaving it takes its old spot.
--
-- Pins: SUPER+G pins the focused window's column, on every workspace of that
-- monitor at once. Whatever sat in that column on any workspace comes over
-- and stacks below the column here, and from then on the column follows you:
-- switching workspaces carries its windows along, tiled. A pin belongs to the
-- column, not to a window, so whatever is dragged or moved into a pinned
-- column is pinned, and whatever leaves it stays behind. Unpinning leaves the
-- windows where you are.
--
-- Pins, spots, heights and the stage seats are saved to
-- ~/.local/state/hypr/stage.lua, so a config reload keeps the columns.
--
-- The lock: Hyprland hands a Lua layout no resize deltas, a drag on a tiled
-- window only re-runs recalculate, so nothing can pull the stage out of 16:9.
-- Side windows get their height on keys instead (layout messages "taller"
-- and "shorter", bound in lua/binds.lua). Floating windows resize as usual.

local M = {}

M.name = "lua:stage"

local RATIO = 16 / 9

-- Side window height weights by window address, 1 when unset.
local weights = {}

-- Spots by window address: { ws = workspace id, side = "left"|"right", key =
-- order in the column }. An entry from another workspace counts as unset, so
-- a window moved here is placed like a new one. The stage window keeps its
-- last entry; it only matters when the window steps down.
local spots = {}
local next_key = 0

-- The stage window per workspace id. Hyprland's own target order is ignored:
-- the stage and the columns are all tracked here.
M.stage_of = {}

-- Addresses tiled on each workspace in the last pass. A known window missing
-- from it is coming back from a mouse drag (Hyprland lifts it out while it
-- moves).
local seen = {}

-- The workspace each window was last tiled on, so one back from a drag is
-- told apart from one that just arrived. Moving a window to another workspace
-- clears it, so a window that comes back that way is placed like a new one.
local home = {}

-- Windows floated by key (SUPER+S). They leave the tiled set the way a
-- dragged one does, so this tells their return apart from a drop.
local lifted = {}

-- While the stage window is away (dragged, or floated), another window stands
-- in on the stage: { by = address of the one away, addr = stand-in, spot =
-- the stand-in's own spot }. It goes back there when the stage window returns.
local stand_in = {}

-- Pinned columns by monitor name: pins["HDMI-A-1"] = { left = true }.
local pins = {}

-- Pinned-column windows floating through a workspace switch, by address.
local riding = {}

local state_dir = (os.getenv("XDG_STATE_HOME") or ((os.getenv("HOME") or "") .. "/.local/state")) .. "/hypr"
local state_file = state_dir .. "/stage.lua"

local function serialize(v)
    if type(v) == "table" then
        local keys = {}
        for k in pairs(v) do keys[#keys + 1] = k end
        table.sort(keys, function(x, y) return tostring(x) < tostring(y) end)
        local out = {}
        for _, k in ipairs(keys) do
            out[#out + 1] = "[" .. serialize(k) .. "]=" .. serialize(v[k])
        end
        return "{" .. table.concat(out, ",") .. "}"
    elseif type(v) == "string" then
        return string.format("%q", v)
    elseif type(v) == "number" then
        return string.format("%.17g", v)
    end
    return tostring(v)
end

local saved
local function save()
    local text = "return " .. serialize({ pins = pins, spots = spots, weights = weights, stage_of = M.stage_of, next_key = next_key })
    if text == saved then return end
    saved = text
    os.execute("mkdir -p '" .. state_dir .. "'")
    local f = io.open(state_file .. ".tmp", "w")
    if not f then return end
    f:write(text, "\n")
    f:close()
    os.rename(state_file .. ".tmp", state_file)
end

-- Restore the last state, keeping only windows that still exist (a restart of
-- Hyprland hands out new addresses).
local function load()
    local chunk = loadfile(state_file, "t", {})
    local ok, st = pcall(chunk or error)
    if not ok or type(st) ~= "table" then return end
    local function alive(a) return type(a) == "string" and hl.get_window("address:" .. a) ~= nil end
    for mon, sides in pairs(st.pins or {}) do
        if type(sides) == "table" then pins[mon] = { left = sides.left == true or nil, right = sides.right == true or nil } end
    end
    for a, e in pairs(st.spots or {}) do
        if alive(a) and type(e) == "table" and (e.side == "left" or e.side == "right") then
            spots[a] = { ws = e.ws, side = e.side, key = e.key }
            home[a] = e.ws
        end
    end
    for a, w in pairs(st.weights or {}) do
        if alive(a) then weights[a] = w end
    end
    for ws, a in pairs(st.stage_of or {}) do
        if alive(a) then M.stage_of[ws] = a end
    end
    next_key = tonumber(st.next_key) or 0
end
load()

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

local function addr(t)
    return t.window and t.window.address
end

local function spot(t, ws)
    local e = spots[addr(t) or ""]
    if e and e.ws == ws then return e end
end

local function put(t, ws, side, key)
    local a = addr(t)
    if not a then return end
    if not key then
        next_key = next_key + 1
        key = next_key
    end
    spots[a] = { ws = ws, side = side, key = key }
end

-- The side windows of each column, top to bottom.
local function columns(targets, ws, stage)
    local cols = { left = {}, right = {} }
    for _, t in ipairs(targets) do
        local e = spot(t, ws)
        if t ~= stage and e then table.insert(cols[e.side], t) end
    end
    for _, c in pairs(cols) do
        table.sort(c, function(x, y) return spot(x, ws).key < spot(y, ws).key end)
    end
    return cols
end

-- The geometry the pass is about to use.
local function frame(a)
    local sw = math.min(math.floor(a.h * RATIO), math.floor(a.w))
    return sw, math.floor((a.w - sw) / 2)
end

-- Step the stage window down into the spot of the one replacing it.
local function promote(ws, t, stage)
    if stage and stage ~= t then
        local e = spot(t, ws)
        if e then put(stage, ws, e.side, e.key) end
    end
    M.stage_of[ws] = addr(t)
    stand_in[ws] = nil
end

-- The stage window is back: the stand-in returns to its spot.
local function release(ws, targets)
    local si = stand_in[ws]
    stand_in[ws] = nil
    if not si then return end
    for _, t in ipairs(targets) do
        if addr(t) == si.addr then spots[si.addr] = si.spot end
    end
end

-- The top window of one column, else of the other.
local function heir(targets, ws, stage, first)
    local cols = columns(targets, ws, stage)
    return cols[first][1] or cols[first == "left" and "right" or "left"][1]
end

-- Land a dragged window where the cursor let go of it.
local function drop(ctx, ws, t, stage)
    local c = hl.get_cursor_pos()
    local a = ctx.area
    local sw, side = frame(a)
    local was_stage = stand_in[ws] and stand_in[ws].by == addr(t)
    if was_stage then
        release(ws, ctx.targets)
        stage = nil
    end
    if not c or side < 1 then
        if was_stage then
            M.stage_of[ws] = addr(t)
            return t
        end
        return stage
    end

    if c.x >= a.x + side and c.x < a.x + side + sw then
        if was_stage then
            M.stage_of[ws] = addr(t)
        else
            promote(ws, t, stage)
        end
        return t
    end

    -- Into a column, above the first window whose middle is below the cursor.
    local to = c.x < a.x + side and "left" or "right"
    local col = columns(ctx.targets, ws, stage)[to]
    local key
    for i, o in ipairs(col) do
        if o ~= t and c.y < o.box.y + o.box.h / 2 then
            local prev = col[i - 1] ~= t and col[i - 1] or col[i - 2]
            local below = spot(o, ws).key
            key = prev and (spot(prev, ws).key + below) / 2 or below - 1
            break
        end
    end
    put(t, ws, to, key)
    if was_stage then
        -- The stage itself was dragged into a column: the top window of the
        -- other column, else of this one, takes the stage.
        stage = heir(ctx.targets, ws, t, to == "left" and "right" or "left") or t
        M.stage_of[ws] = addr(stage)
    end
    return stage
end

local function recalculate(ctx)
    local a, targets = ctx.area, ctx.targets
    if #targets == 0 then return end

    local w0 = targets[1].window
    local ws = w0 and w0.workspace and w0.workspace.id
    if not ws then
        stack(targets, a.x, a.y, a.w, a.h)
        return
    end

    local before = seen[ws]
    local now, back = {}, {}
    for _, t in ipairs(targets) do
        local a_ = addr(t)
        if a_ then
            now[a_] = true
            back[a_] = home[a_] == ws and not lifted[a_]
            home[a_] = ws
        end
    end
    seen[ws] = now

    local stage
    for _, t in ipairs(targets) do
        if addr(t) == M.stage_of[ws] then stage = t end
    end

    if not before then
        -- First pass since a reload: the saved spots hold; any window without
        -- one is dealt out the old way, right then left, in Hyprland's order.
        stage = stage or targets[1]
        M.stage_of[ws] = addr(stage)
        local n = 0
        for _, t in ipairs(targets) do
            if t ~= stage and not spot(t, ws) then
                n = n + 1
                put(t, ws, n % 2 == 1 and "right" or "left")
            end
        end
        before = now
    end

    -- Sort out who is new, who is back from a drag, and who is back from
    -- floating (that one keeps its spot).
    local new, dropped, is_new = {}, {}, {}
    for _, t in ipairs(targets) do
        local a_ = addr(t)
        if a_ and not before[a_] then
            local si = stand_in[ws]
            if lifted[a_] and si and si.by == a_ then
                -- The stage window, floated and tiled again: back on stage.
                release(ws, targets)
                M.stage_of[ws] = a_
                stage = t
            elseif back[a_] then
                table.insert(dropped, t)
            elseif not spot(t, ws) then
                -- A window with a spot here already was floated by key, or
                -- carried over by a pin, and keeps it.
                table.insert(new, t)
            end
            lifted[a_] = nil
        elseif a_ and not spot(t, ws) and t ~= stage then
            table.insert(new, t)
        end
    end
    for _, t in ipairs(new) do is_new[t] = true end

    -- No stage on this workspace. If its window is only away (dragged or
    -- floated), the top side window stands in until it returns; if it
    -- closed, the stand-in just keeps the stage.
    if not stage then
        local away = M.stage_of[ws]
        stage = heir(targets, ws, nil, "left")
        if not stage then
            for _, t in ipairs(targets) do
                if not is_new[t] then stage = t break end
            end
        end
        if not stage then
            stage = table.remove(new, 1)
            is_new[stage] = nil
        end
        if away and hl.get_window("address:" .. away) and not (stand_in[ws] and stand_in[ws].addr == addr(stage)) then
            local e = spots[addr(stage) or ""]
            stand_in[ws] = { by = away, addr = addr(stage), spot = e }
        end
        M.stage_of[ws] = addr(stage)
    end

    for _, t in ipairs(dropped) do
        stage = drop(ctx, ws, t, stage)
    end

    if #new > 0 then
        -- The window focused before the newcomers: lowest focus history among
        -- the ones already placed (a newcomer itself usually holds 0).
        local prior, best
        for _, t in ipairs(targets) do
            local id = t.window and t.window.focus_history_id
            if not is_new[t] and id and id >= 0 and (not best or id < best) then
                prior, best = t, id
            end
        end
        local cols = columns(targets, ws, stage)
        local count = { left = #cols.left, right = #cols.right }
        for _, t in ipairs(new) do
            local side
            if prior and prior ~= stage and spot(prior, ws) then
                side = spot(prior, ws).side
            elseif count.left > 0 and count.right == 0 then
                side = "right"
            else
                side = "left"
            end
            put(t, ws, side)
            count[side] = count[side] + 1
        end
    end

    local sw, side = frame(a)

    -- No room beside the stage (a monitor no wider than 16:9): one column.
    if side < 1 then
        stack(targets, a.x, a.y, a.w, a.h)
        return
    end

    stage:place({ x = a.x + side, y = a.y, w = sw, h = a.h })
    local cols = columns(targets, ws, stage)
    stack(cols.left, a.x, a.y, side, a.h)
    stack(cols.right, a.x + side + sw, a.y, a.w - side - sw, a.h)
    save()
end

local steps = { taller = 1.25, shorter = 0.8 }

-- The nearest window from t in a direction, by the boxes of the last pass.
local function neighbour(targets, t, dir)
    local b = t.box
    local cx, cy = b.x + b.w / 2, b.y + b.h / 2
    local best, dist
    for _, o in ipairs(targets) do
        if o ~= t then
            local ob = o.box
            local ox, oy = ob.x + ob.w / 2, ob.y + ob.h / 2
            local ahead = (dir == "left" and ob.x + ob.w <= b.x + 1)
                or (dir == "right" and ob.x >= b.x + b.w - 1)
                or (dir == "up" and ob.y + ob.h <= b.y + 1 and ob.x < b.x + b.w and ob.x + ob.w > b.x)
                or (dir == "down" and ob.y >= b.y + b.h - 1 and ob.x < b.x + b.w and ob.x + ob.w > b.x)
            local d = (ox - cx) ^ 2 + (oy - cy) ^ 2
            if ahead and (not dist or d < dist) then best, dist = o, d end
        end
    end
    return best
end

-- Unknown messages are ignored, not refused: a refusal is a config error,
-- and that banner would sit on stream.
local function layout_msg(ctx, msg)
    local active = hl.get_active_window()
    if not active or not active.workspace then return end
    local ws = active.workspace.id
    local t, stage
    for _, o in ipairs(ctx.targets) do
        if addr(o) == active.address then t = o end
        if addr(o) == M.stage_of[ws] then stage = o end
    end
    if not t then return end

    local verb, dir = msg:match("^(%a+) (%a+)$")
    local e = spot(t, ws)

    if msg == "stage" then
        promote(ws, t, stage)
    elseif steps[msg] then
        if t ~= stage then
            weights[active.address] = math.max(0.25, math.min((weights[active.address] or 1) * steps[msg], 4))
        end
    elseif verb == "side" and t ~= stage and e and (dir == "left" or dir == "right") then
        put(t, ws, dir)
    elseif verb == "shift" and t ~= stage and e and (dir == "up" or dir == "down") then
        local col = columns(ctx.targets, ws, stage)[e.side]
        for i, o in ipairs(col) do
            local other = col[i + (dir == "up" and -1 or 1)]
            if o == t and other then
                local oe = spot(other, ws)
                e.key, oe.key = oe.key, e.key
                break
            end
        end
    elseif verb == "swap" then
        local o = neighbour(ctx.targets, t, dir)
        if not o then return end
        local oe = spot(o, ws)
        if t == stage then
            promote(ws, o, t)
        elseif o == stage then
            promote(ws, t, o)
        elseif e and oe then
            spots[addr(t)], spots[addr(o)] = oe, e
        end
    end
    save()
end

hl.layout.register("stage", { recalculate = recalculate, layout_msg = layout_msg })

-- A window that leaves for good takes its state along, so an address Hyprland
-- hands out again starts clean.
local function forget(w, keep_ws)
    local a = w and w.address
    if not a then return end
    -- A spot on the workspace it went to is already its new one (that pass
    -- can run before this event), or was set by a pin carrying it there.
    if not (keep_ws and spots[a] and spots[a].ws == keep_ws) then
        spots[a] = nil
    end
    if home[a] ~= keep_ws then home[a] = nil end
    for ws, si in pairs(stand_in) do
        if si.by == a or si.addr == a then stand_in[ws] = nil end
    end
    for ws, s in pairs(M.stage_of) do
        if s == a and ws ~= keep_ws then M.stage_of[ws] = nil end
    end
end

hl.on("window.close", function(w)
    forget(w)
    if w and w.address then weights[w.address], lifted[w.address], riding[w.address] = nil, nil, nil end
end)

hl.on("window.move_to_workspace", function(w, ws)
    forget(w, ws and ws.id)
    save()
end)

local function stage_ws(ws)
    return ws and not ws.special and ws.tiled_layout == M.name
end

-- Bring every window of the pinned columns on monitor mon over to workspace
-- ws. With fresh set (the moment of pinning), the ones already here stay on
-- top and the rest stack below them, by workspace.
local function carry(mon, ws, fresh)
    local p = pins[mon]
    if not p or not (p.left or p.right) then return end
    local target = hl.get_workspace(ws)
    if not stage_ws(target) then return end
    local here, away = {}, {}
    for _, w in ipairs(hl.get_windows()) do
        local e = spots[w.address]
        local wws = w.workspace
        if e and stage_ws(wws) and e.ws == wws.id and p[e.side] and not w.floating
            and wws.monitor and wws.monitor.name == mon and M.stage_of[e.ws] ~= w.address then
            table.insert(wws.id == ws and here or away, { w = w, e = e })
        end
    end
    if fresh then
        table.sort(here, function(x, y) return x.e.key < y.e.key end)
        table.sort(away, function(x, y)
            if x.e.ws ~= y.e.ws then return x.e.ws < y.e.ws end
            return x.e.key < y.e.key
        end)
        for _, list in ipairs({ here, away }) do
            for _, it in ipairs(list) do
                next_key = next_key + 1
                it.e.key = next_key
            end
        end
    end
    for _, it in ipairs(away) do
        -- The spot moves first, so the pass on the new workspace finds it
        -- whichever comes first, the pass or the move event.
        it.e.ws = ws
        hl.dispatch(hl.dsp.window.move({ workspace = ws, follow = false, window = "address:" .. it.w.address }))
    end
    save()
end

-- Riding a workspace switch. A tiled window belongs to one workspace, so it
-- would slide out with the old one and fade in on the new one. For the length
-- of the slide the pinned column's windows float at their exact box with
-- Hyprland's own pin, which keeps a window still on screen through the
-- animation; then they tile again, in the same spot, on the new workspace.
local ride_timer

local function sel(a) return "address:" .. a end

local function xy(v)
    if type(v) == "table" then return v.x or v[1], v.y or v[2] end
end

local function settle()
    ride_timer = nil
    for a in pairs(riding) do
        local w = hl.get_window(sel(a))
        local ws = w and w.monitor and w.monitor.active_workspace
        if w and ws and spots[a] then
            spots[a].ws = ws.id
            lifted[a] = true
            hl.dispatch(hl.dsp.window.pin({ action = "unset", window = sel(a) }))
            if not w.workspace or w.workspace.id ~= ws.id then
                hl.dispatch(hl.dsp.window.move({ workspace = ws.id, follow = false, window = sel(a) }))
            end
            hl.dispatch(hl.dsp.window.float({ action = "unset", window = sel(a) }))
        end
        if w then
            hl.dispatch(hl.dsp.window.tag({ tag = "-stageride", window = sel(a) }))
            hl.dispatch(hl.dsp.window.set_prop({ prop = "no_anim", value = "unset", window = sel(a) }))
        end
    end
    riding = {}
    save()
end

local function ride(mon, ws)
    local p = pins[mon]
    if not p or not (p.left or p.right) then return end
    local target = hl.get_workspace(ws)
    if not stage_ws(target) then return end
    local any = false
    for _, w in ipairs(hl.get_windows()) do
        local a = w.address
        local e = spots[a]
        local wws = w.workspace
        if e and not riding[a] and stage_ws(wws) and wws.id ~= ws and e.ws == wws.id and p[e.side]
            and not w.floating and wws.monitor and wws.monitor.name == mon and M.stage_of[e.ws] ~= a then
            local x, y = xy(w.at)
            local bw, bh = xy(w.size)
            if x and bw then
                riding[a], lifted[a], any = true, true, true
                e.ws = ws
                hl.dispatch(hl.dsp.window.set_prop({ prop = "no_anim", value = "1", window = sel(a) }))
                hl.dispatch(hl.dsp.window.tag({ tag = "+stageride", window = sel(a) }))
                hl.dispatch(hl.dsp.window.float({ action = "set", window = sel(a) }))
                hl.dispatch(hl.dsp.window.resize({ x = bw, y = bh, window = sel(a) }))
                hl.dispatch(hl.dsp.window.move({ x = x, y = y, window = sel(a) }))
                hl.dispatch(hl.dsp.window.pin({ action = "set", window = sel(a) }))
            end
        end
    end
    if any or next(riding) then
        -- Another switch mid-slide keeps them riding until the last one ends.
        if ride_timer then ride_timer:set_enabled(false) end
        local slide = hl.get_config("animations.enabled") and 500 or 30
        ride_timer = hl.timer(settle, { timeout = slide, type = "oneshot" })
    end
end

hl.on("workspace.active", function()
    for _, m in ipairs(hl.get_monitors()) do
        local ws = m.active_workspace
        if ws and not ws.special and pins[m.name] then ride(m.name, ws.id) end
    end
end)

-- The focused window, if it is tiled on a stage.
function M.window()
    local w = hl.get_active_window()
    if not w or not w.workspace or not w.layout or w.layout.name ~= M.name then return nil end
    return w
end

-- Swap the focused window onto the stage; the window that was there takes its
-- place beside it. Focus stays on the window that moved.
function M.put_on_stage()
    if M.window() then
        hl.dispatch(hl.dsp.layout("stage"))
    end
end

-- Whether a side window has a neighbour in its column toward dir.
local function has_neighbour(w, e, dir)
    for _, o in ipairs(hl.get_workspace_windows(w.workspace.id)) do
        local oe = spots[o.address]
        if o.address ~= w.address and not o.floating and oe and oe.ws == e.ws
            and oe.side == e.side and o.address ~= M.stage_of[e.ws]
            and (dir == "up" and oe.key < e.key or dir == "down" and oe.key > e.key) then
            return true
        end
    end
    return false
end

-- SUPER+SHIFT+direction. On a stage, LEFT/RIGHT carry a side window into the
-- other column and UP/DOWN move it inside its column; neither touches the
-- stage. The stage window itself, a side window pointing out of its column,
-- and every other layout get the stock move (onto another monitor).
function M.move(dir)
    return function()
        local w = M.window()
        local e = w and spots[w.address]
        if w and e and e.ws == w.workspace.id and M.stage_of[e.ws] ~= w.address then
            if (dir == "up" or dir == "down") and has_neighbour(w, e, dir) then
                hl.dispatch(hl.dsp.layout("shift " .. dir))
                return
            end
            if (dir == "left" or dir == "right") and e.side ~= dir then
                hl.dispatch(hl.dsp.layout("side " .. dir))
                return
            end
        end
        hl.dispatch(hl.dsp.window.move({ direction = dir }))
    end
end

-- SUPER+G. On a tiled stage window, pin or unpin its column; otherwise
-- Hyprland's own pin (floating windows).
function M.pin()
    local w = M.window()
    local e = w and not w.floating and spots[w.address]
    if not e or e.ws ~= w.workspace.id or M.stage_of[e.ws] == w.address or not w.workspace.monitor then
        hl.dispatch(hl.dsp.window.pin())
        return
    end
    local mon = w.workspace.monitor.name
    pins[mon] = pins[mon] or {}
    local on = not pins[mon][e.side]
    pins[mon][e.side] = on or nil
    pcall(hl.notification.create, { text = (on and "Pinned " or "Unpinned ") .. e.side .. " column", timeout = 1500 })
    if on then carry(mon, e.ws, true) end
    save()
end

-- SUPER+S. Marks the window first, so the layout knows a window that comes
-- back tiled was floated, not dragged.
function M.float_toggle()
    local w = hl.get_active_window()
    if w then lifted[w.address] = true end
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
end

-- SUPER+ALT+direction: trade places with the neighbouring window. Taking or
-- leaving the stage this way works like putting a window on it.
function M.swap(dir)
    return function()
        if M.window() then
            hl.dispatch(hl.dsp.layout("swap " .. dir))
        else
            hl.dispatch(hl.dsp.window.swap({ direction = dir }))
        end
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
