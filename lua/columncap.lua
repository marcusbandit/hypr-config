-- Column cap for the scrolling layout.
--
-- Scrolling grows an infinite tape of columns; this module puts a ceiling on
-- that. When a window opens on a workspace already at the cap, it does not
-- get a column of its own: it is folded back into the column beside it, so
-- the tape never gets wider than the cap and overflow stacks inside the
-- last column instead.
--
-- The cap is per workspace, floating windows are ignored, and the fold uses
-- the scrolling layout's own consume_or_expel verb, so the layout stays in
-- charge of the geometry.

local CAP = 3
local X_TOLERANCE = 30 -- px; windows closer than this on x share a column

local repairing = false

local M = {}

local function tiled_windows(ws_id)
    local out = {}
    for _, w in ipairs(hl.get_workspace_windows(ws_id)) do
        if not w.floating then
            table.insert(out, w)
        end
    end
    return out
end

-- Cluster tiled windows into columns by their x position, left to right.
-- Window positions are dicts: w.at.x / w.at.y.
local function columns_of(ws_id)
    local wins = tiled_windows(ws_id)
    table.sort(wins, function(a, b) return a.at.x < b.at.x end)
    local cols = {}
    for _, w in ipairs(wins) do
        local last = cols[#cols]
        if last and math.abs(w.at.x - last[1].at.x) < X_TOLERANCE then
            table.insert(last, w)
        else
            table.insert(cols, { w })
        end
    end
    return cols
end

local function col_of(w, cols)
    for i, col in ipairs(cols) do
        for _, c in ipairs(col) do
            if c.address == w.address then
                return i
            end
        end
    end
end

function M.cap()
    return CAP
end

function M.set_cap(n)
    CAP = n
end

hl.on("window.open", function(w)
    if repairing or w.floating then return end
    local ws_id = w.workspace and w.workspace.id
    if not ws_id then return end

    repairing = true

    repairing = true
    local ok, err = pcall(function()
        local cols = columns_of(ws_id)
        local ci = col_of(w, cols)
        -- act only when the window opened as a fresh single-window column
        -- and that column pushed the workspace past the cap
        if not ci or #cols[ci] > 1 or #cols <= CAP then return end

        -- fold the new column back into its left neighbour (the column it
        -- appeared next to); at the left edge, fold right instead
        local verb = ci > 1 and "prev" or "next"
        hl.dsp.focus({ window = w })
        hl.dispatch(hl.dsp.layout("consume_or_expel " .. verb))
    end)
    repairing = false
    if not ok then error(err) end
end)

return M
