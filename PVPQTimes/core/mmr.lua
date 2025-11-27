local ADDON_NAME, NS = ...

local function EnsureMMRDB()
    NS.db.mmr = NS.db.mmr or {}
    return NS.db.mmr
end

function NS.GetLastMMRForBracket(bracket)
    if not NS.TRACKED_MMR_BRACKETS[bracket] then return nil end

    local db = NS.db.mmr
    if not db then return nil end

    local entry = db[bracket]
    if not entry or entry.pre <= 0 or entry.post <= 0 then return nil end

    return "MMR", entry.pre, entry.post, entry.change
end

function NS.TrackLatestMMR()
    local C = C_PvP
    if not C or not C.GetScoreInfoByPlayerGuid then return end

    local bracket = C.GetActiveMatchBracket()
    if not NS.TRACKED_MMR_BRACKETS[bracket] then return end

    local guid = UnitGUID("player")
    if not guid then return end

    local info = C.GetScoreInfoByPlayerGuid(guid)
    if not info or not info.postmatchMMR or info.postmatchMMR <= 0 then return end

    local db = EnsureMMRDB()
    db[bracket] = {
        pre    = info.prematchMMR,
        post   = info.postmatchMMR,
        change = info.postmatchMMR - info.prematchMMR,
    }
end