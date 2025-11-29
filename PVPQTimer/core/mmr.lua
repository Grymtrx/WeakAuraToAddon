local ADDON_NAME, NS = ...

------------------------------------------------
-- Helpers
------------------------------------------------

-- Stable per-character key: "Name-Realm"
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

-- Ensure the SavedVariables tree exists and return the char+mmr tables.
-- We work directly on PVPQTimerDB so we never get out of sync with SavedVariables.
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
-- WRITE: store last MMR for this char + bracket + spec
------------------------------------------------

local function StoreLatestMMR(bracket, specName, pre, post, change)
    -- Only track brackets we explicitly care about (6 = Shuffle, 8 = Blitz)
    if NS.TRACKED_MMR_BRACKETS and not NS.TRACKED_MMR_BRACKETS[bracket] then
        return
    end

    if not specName or specName == "" then
        return
    end

    if not pre or not post or pre <= 0 or post <= 0 then
        return
    end

    local db, charDB = EnsureCharTables()

    local mmrByBracket = charDB.mmr
    local bracketTable = mmrByBracket[bracket]
    if not bracketTable then
        bracketTable = {}
        mmrByBracket[bracket] = bracketTable
    end

    -- Per spec name (e.g. "Restoration", "Enhancement", "Discipline")
    bracketTable[specName] = {
        pre    = pre,
        post   = post,
        change = change or (post - pre),
        spec   = specName,
        at     = time(),  -- timestamp if you ever want history/debug
    }
end

------------------------------------------------
-- READ: last MMR for *this* char + bracket + current spec
--
-- IMPORTANT:
--  • No fallback to other specs.
--  • No “_last” / “any entry” fallback.
--  • If you haven’t played this spec in this bracket, you get nil.
------------------------------------------------

function NS.GetLastMMRForBracket(bracket)
    if not bracket or bracket <= 0 then
        return nil
    end

    -- Respect tracked brackets if defined
    if NS.TRACKED_MMR_BRACKETS and not NS.TRACKED_MMR_BRACKETS[bracket] then
        return nil
    end

    local db = PVPQTimerDB
    if not db or not db.chars then
        return nil
    end

    local charKey = GetCharKey()
    local charDB  = db.chars[charKey]
    if not charDB or not charDB.mmr then
        return nil
    end

    local specName = GetCurrentSpecName()
    if not specName or specName == "" then
        return nil
    end

    local bracketTable = charDB.mmr[bracket]
    if not bracketTable then
        return nil
    end

    local entry = bracketTable[specName]
    if not entry then
        -- No MMR recorded yet for this spec in this bracket
        return nil
    end

    -- Extra sanity: if stored spec doesn't match, bail
    if entry.spec and entry.spec ~= specName then
        return nil
    end

    local pre    = entry.pre or 0
    local post   = entry.post or 0
    local change = entry.change or (post - pre)

    if pre <= 0 or post <= 0 then
        return nil
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

    -- Prefer Blizzard's talentSpec string; fallback to current spec
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
