local ADDON_NAME, NS = ...

------------------------------------------------
-- Debug helper
------------------------------------------------
local function D(...)
    if NS and NS.DebugPrint then
        NS.DebugPrint(...)
    else
        print("|cffa0ffa0PVPQTimer|r", ...)
    end
end

------------------------------------------------
-- Per-character, per-spec MMR storage
------------------------------------------------

-- Build a stable key like "Name-Realm"
local function GetCharKey()
    local name, realm = UnitFullName("player")
    if not name then
        return "UNKNOWN"
    end
    if realm and realm ~= "" then
        return name .. "-" .. realm
    end
    return name
end

-- Ensure we have a mmr table for this character
-- Shape:
--   NS.db.chars[charKey].mmr[bracket][specName] = { pre, post, change, at }
--   NS.db.chars[charKey].mmr[bracket]._last     = lastEntry
local function EnsureMMRDB()
    if not NS.db then
        NS.db = {}
    end

    NS.db.chars = NS.db.chars or {}

    local charKey = GetCharKey()
    local charDB  = NS.db.chars[charKey]
    if not charDB then
        charDB = {}
        NS.db.chars[charKey] = charDB
        D("EnsureMMRDB: created charDB for", charKey)
    end

    charDB.mmr = charDB.mmr or {}
    return charDB.mmr, charKey
end

local function GetCurrentSpecName()
    local currentSpec = GetSpecialization and GetSpecialization()
    if not currentSpec then
        return nil
    end

    local _, specName = GetSpecializationInfo(currentSpec)
    return specName
end

------------------------------------------------
-- WRITE: per character, per bracket, per spec
------------------------------------------------
local function StoreLatestMMR(bracket, specName, pre, post, change)
    -- Only track brackets we care about (6 = Shuffle, 8 = Blitz)
    if NS.TRACKED_MMR_BRACKETS and not NS.TRACKED_MMR_BRACKETS[bracket] then
        D("StoreLatestMMR: bracket", bracket, "not tracked")
        return
    end
    if not specName or specName == "" then
        D("StoreLatestMMR: missing specName, abort")
        return
    end

    local mmrDB, charKey = EnsureMMRDB()

    if not mmrDB[bracket] then
        mmrDB[bracket] = {}
        D("StoreLatestMMR: created bracket table", bracket, "for", charKey)
    end

    local entry = {
        pre    = pre,
        post   = post,
        change = change,
        spec   = specName,
        at     = time(),
    }

    mmrDB[bracket][specName] = entry
    mmrDB[bracket]._last     = entry

    D(string.format(
        "StoreLatestMMR: %s bracket=%d spec=%s pre=%d post=%d change=%+d",
        charKey, bracket, specName, pre or -1, post or -1, change or 0
    ))
end

------------------------------------------------
-- READ: per character, per bracket, per spec
--  1) Try current spec key
--  2) Fallback to _last if missing
------------------------------------------------
function NS.GetLastMMRForBracket(bracket)
    D("GetLastMMRForBracket: called for bracket", bracket)

    if not bracket or bracket <= 0 then
        D("GetLastMMRForBracket: invalid bracket", bracket)
        return
    end

    if not NS.db or not NS.db.chars then
        D("GetLastMMRForBracket: NS.db or NS.db.chars missing")
        return
    end

    local charKey = GetCharKey()
    local charDB  = NS.db.chars[charKey]
    if not charDB then
        D("GetLastMMRForBracket: no charDB for", charKey)
        return
    end

    local mmrDB = charDB.mmr
    if not mmrDB then
        D("GetLastMMRForBracket: no mmr table for", charKey)
        return
    end

    local bracketTable = mmrDB[bracket]
    if not bracketTable then
        D("GetLastMMRForBracket: no bracket table for", charKey, "bracket", bracket)
        return
    end

    -- Dump available spec keys for this bracket (for debugging)
    local available = {}
    for k, v in pairs(bracketTable) do
        table.insert(available, tostring(k))
    end
    D("GetLastMMRForBracket: bracket", bracket, "has keys:", table.concat(available, ", "))

    -- Try current spec first
    local specName = GetCurrentSpecName()
    D("GetLastMMRForBracket: current specName =", specName or "nil")

    local entry
    if specName and specName ~= "" then
        entry = bracketTable[specName]
        if entry then
            D("GetLastMMRForBracket: found entry for spec", specName)
        else
            D("GetLastMMRForBracket: no entry for spec", specName, "falling back to _last")
        end
    else
        D("GetLastMMRForBracket: no specName, falling back to _last")
    end

    if not entry then
        entry = bracketTable._last
        if entry then
            D("GetLastMMRForBracket: using _last entry spec", entry.spec or "nil")
        else
            D("GetLastMMRForBracket: no _last entry, giving up")
            return
        end
    end

    local pre    = entry.pre or 0
    local post   = entry.post or 0
    local change = entry.change or (post - pre)

    if pre <= 0 or post <= 0 then
        D("GetLastMMRForBracket: pre/post invalid", pre, post)
        return
    end

    -- Label for the UI
    local label
    if bracket == 6 then
        label = "Solo Shuffle"
    elseif bracket == 8 then
        label = "Blitz"
    else
        label = "Bracket " .. tostring(bracket)
    end

    D(string.format(
        "GetLastMMRForBracket: returning %s pre=%d post=%d change=%+d",
        label, pre, post, change
    ))

    return label, pre, post, change
end

------------------------------------------------
-- Capture latest Shuffle/Blitz MMR after a game
------------------------------------------------
function NS.TrackLatestMMR()
    local C = C_PvP
    if not C or not C.GetScoreInfoByPlayerGuid or not C.GetActiveMatchBracket then
        D("TrackLatestMMR: missing C_PvP API")
        return
    end

    local bracket = C.GetActiveMatchBracket()
    D("TrackLatestMMR: active bracket =", bracket)

    if not bracket or bracket <= 0 then
        D("TrackLatestMMR: invalid bracket", bracket)
        return
    end

    if NS.TRACKED_MMR_BRACKETS and not NS.TRACKED_MMR_BRACKETS[bracket] then
        D("TrackLatestMMR: bracket", bracket, "not tracked")
        return
    end

    local guid = UnitGUID("player")
    if not guid then
        D("TrackLatestMMR: no player GUID")
        return
    end

    local info = C.GetScoreInfoByPlayerGuid(guid)
    if not info then
        D("TrackLatestMMR: no score info")
        return
    end

    if not info.postmatchMMR or info.postmatchMMR <= 0 then
        D("TrackLatestMMR: postmatchMMR invalid", info.postmatchMMR)
        return
    end

    local pre  = info.prematchMMR
    local post = info.postmatchMMR
    if not pre or not post or pre <= 0 or post <= 0 then
        D("TrackLatestMMR: pre/post invalid", pre or 0, post or 0)
        return
    end

    -- Prefer Blizzard's talentSpec string; fallback to current spec
    local specName = info.talentSpec
    if not specName or specName == "" then
        specName = GetCurrentSpecName()
    end
    if not specName or specName == "" then
        specName = "Unknown"
    end

    local change = post - pre

    D(string.format(
        "TrackLatestMMR: bracket=%d spec=%s pre=%d post=%d change=%+d",
        bracket, specName, pre, post, change
    ))

    StoreLatestMMR(bracket, specName, pre, post, change)
end
