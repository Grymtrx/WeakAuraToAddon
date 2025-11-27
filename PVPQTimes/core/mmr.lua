local ADDON_NAME, NS = ...

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
local function EnsureMMRDB()
    NS.db.chars = NS.db.chars or {}

    local charKey = GetCharKey()
    local charDB  = NS.db.chars[charKey]
    if not charDB then
        charDB = {}
        NS.db.chars[charKey] = charDB
    end

    charDB.mmr = charDB.mmr or {}
    return charDB.mmr
end

local function GetCurrentSpecName()
    local currentSpec = GetSpecialization and GetSpecialization()
    if not currentSpec then
        return nil
    end

    local _, specName = GetSpecializationInfo(currentSpec)
    return specName
end

-- Write: per character, per bracket, per spec
local function StoreLatestMMR(bracket, specName, pre, post, change)
    if not NS.TRACKED_MMR_BRACKETS[bracket] then
        return
    end
    if not specName or specName == "" then
        return
    end

    local mmrDB = EnsureMMRDB()

    -- Per bracket (6 = Shuffle, 8 = Blitz)
    if not mmrDB[bracket] then
        mmrDB[bracket] = {}
    end

    -- Per spec name (e.g. "Discipline", "Feral")
    mmrDB[bracket][specName] = {
        pre    = pre,
        post   = post,
        change = change,
    }
end

-- Read: per character, per bracket, current spec
function NS.GetLastMMRForBracket(bracket)
    if not NS.TRACKED_MMR_BRACKETS[bracket] then
        return nil
    end

    local chars = NS.db.chars
    if not chars then
        return nil
    end

    local charKey = GetCharKey()
    local charDB  = chars[charKey]
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
        return nil
    end

    local pre    = entry.pre or 0
    local post   = entry.post or 0
    local change = entry.change or (post - pre)

    if pre <= 0 or post <= 0 then
        return nil
    end

    -- We always show MMR, never CR
    return "MMR", pre, post, change
end

-- Capture latest Shuffle/Blitz MMR after a game
function NS.TrackLatestMMR()
    local C = C_PvP
    if not C or not C.GetScoreInfoByPlayerGuid or not C.GetActiveMatchBracket then
        return
    end

    local bracket = C.GetActiveMatchBracket()
    if not NS.TRACKED_MMR_BRACKETS[bracket] then
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