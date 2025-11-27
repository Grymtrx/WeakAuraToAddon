local addonName, ns = ...

-- Bracket definition helper
local function B(id, key, anchorPath)
    return { id = id, key = key, anchorPath = anchorPath }
end

ns.BRACKETS = {
    B(7,  "Solo",   "ConquestFrame.RatedSoloShuffle.CurrentRating"),
    B(1,  "2v2",    "ConquestFrame.Arena2v2.CurrentRating"),
    B(2,  "3v3",    "ConquestFrame.Arena3v3.CurrentRating"),
    B(10, "BGBlitz","ConquestFrame.RatedBGBlitz.CurrentRating"),
    B(3,  "BG",     "ConquestFrame.RatedBG.CurrentRating"),
}

-- Returns wins, losses, winrate OR nil if no games played
function ns.GetStats(id)
    local total, wins

    if id == 7 then
        -- Solo Shuffle
        total = select(12, GetPersonalRatedInfo(id))
        wins  = select(13, GetPersonalRatedInfo(id))
    else
        -- 2v2 / 3v3 / BG / BGBlitz
        total = select(4, GetPersonalRatedInfo(id))
        wins  = select(5, GetPersonalRatedInfo(id))
    end

    if not total or total == 0 or not wins then
        return nil
    end

    local losses  = total - wins
    local winrate = (wins / total) * 100
    return wins, losses, winrate
end
