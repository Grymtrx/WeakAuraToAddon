local ADDON_NAME, NS = ...

------------------------------------------------
-- Helpers
------------------------------------------------

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

local function GetCurrentSpecName()
    local currentSpec = GetSpecialization and GetSpecialization()
    if not currentSpec then
        return nil
    end
    local _, specName = GetSpecializationInfo(currentSpec)
    return specName
end

-- Ensure the root SavedVariables table and char subtree exist.
-- We DO NOT go through NS.db here; we go straight to the global
-- that WoW persists: PVPQTimerDB.
local function EnsureCharTables()
    PVPQTimerDB = PVPQTimerDB or {}
    PVPQTimerDB.chars = PVPQTimerDB.chars or {}

    local charKey = GetCharKey()
    local charDB  = PVPQTimerDB.chars[charKey]
    if not charDB then
        charDB = {}
        PVPQTimerDB.chars[charKey] = charDB
    end

    charDB.mmr = charDB.mmr or {}

    return PVPQTimerDB, charDB, charKey
end

------------------------------------------------
-- WRITE: store last MMR per bracket & spec
------------------------------------------------

local function StoreLatestMMR(bracket, specName, pre, post, change)
    if not bracket or bracket <= 0 then
        return
    end
    if not pre or not post or pre <= 0 or post <= 0 then
        return
    end

    -- Only track the brackets we care about (if defined)
    if NS.TRACKED_MMR_BRACKETS and not NS.TRACKED_MMR_BRACKETS[bracket] then
        return
    end

    local db, charDB, charKey = EnsureCharTables()

    specName = specName or GetCurrentSpecName() or "Unknown"

    local mmrByBracket = charDB.mmr
    local bracketTable = mmrByBracket[bracket]
    if not bracketTable then
        bracketTable = {}
        mmrByBracket[bracket] = bracketTable
    end

    local entry = {
        pre    = pre,
        post   = post,
        change = change or (post - pre),
        spec   = specName,
        at     = time(),  -- timestamp for future debugging if needed
    }

    bracketTable[specName] = entry
    bracketTable._last     = entry  -- cache "last seen" entry for this bracket
end

------------------------------------------------
-- READ: return last MMR for this bracket on this char
--  1) Try current spec
--  2) Fallback to `_last`
--  3) Fallback to any valid entry
------------------------------------------------

function NS.GetLastMMRForBracket(bracket)
    if not bracket or bracket <= 0 then
        return
    end

    local db = PVPQTimerDB
    if not db or not db.chars then
        return
    end

    local charKey = GetCharKey()
    local charDB  = db.chars[charKey]
    if not charDB or not charDB.mmr then
        return
    end

    local bracketTable = charDB.mmr[bracket]
    if not bracketTable then
        return
    end

    -- 1) Try current spec key
    local specName = GetCurrentSpecName()
    local entry

    if specName and specName ~= "" then
        entry = bracketTable[specName]
    end

    -- 2) Fallback: `_last` if spec lookup failed
    if not entry then
        entry = bracketTable._last
    end

    -- 3) Fallback: first valid entry in this bracket
    if not entry then
        for key, value in pairs(bracketTable) do
            if type(value) == "table" and value.pre and value.post then
                entry = value
                break
            end
        end
    end

    if not entry then
        return
    end

    local pre    = entry.pre or 0
    local post   = entry.post or 0
    local change = entry.change or (post - pre)

    if pre <= 0 or post <= 0 then
        return
    end

    local label
    if bracket == 6 then
        label = "MMR (Shuffle)"
    elseif bracket == 8 then
        label = "MMR (Blitz)"
    else
        label = "MMR"
    end

    return label, pre, post, change
end

------------------------------------------------
-- CAPTURE: called after a rated PvP match completes
------------------------------------------------

function NS.TrackLatestMMR()
    local C = C_PvP
    if not C or not C.GetScoreInfoByPlayerGuid or not C.GetActiveMatchBracket then
        return
    end

    local bracket = C.GetActiveMatchBracket()
    if not bracket or bracket <= 0 then
        return
    end

    -- Honor NS.TRACKED_MMR_BRACKETS here as well
    if NS.TRACKED_MMR_BRACKETS and not NS.TRACKED_MMR_BRACKETS[bracket] then
        return
    end

    local guid = UnitGUID("player")
    if not guid then
        return
    end

    local info = C.GetScoreInfoByPlayerGuid(guid)
    if not info or not info.postmatchMMR or info.postmatchMMR <= 0 then
        return
    end

    local pre  = info.prematchMMR
    local post = info.postmatchMMR
    if not pre or not post or pre <= 0 or post <= 0 then
        return
    end

    local specName = info.talentSpec
    if not specName or specName == "" then
        specName = GetCurrentSpecName()
    end
    if not specName or specName == "" then
        specName = "Unknown"
    end

    local change = post - pre
    StoreLatestMMR(bracket, specName, pre, post, change)
end
