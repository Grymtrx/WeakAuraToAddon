local addonName, ns = ...

local CLASS_ORDER = {"DEATHKNIGHT", "DEMONHUNTER", "DRUID", "EVOKER", "HUNTER", "MAGE", "MONK", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR"}
ns.CLASS_ORDER = CLASS_ORDER

local CLASS_MASKS = {
    [1] = "WARRIOR",
    [2] = "PALADIN",
    [4] = "HUNTER",
    [8] = "ROGUE",
    [16] = "PRIEST",
    [32] = "DEATHKNIGHT",
    [64] = "SHAMAN",
    [128] = "MAGE",
    [256] = "WARLOCK",
    [512] = "MONK",
    [1024] = "DRUID",
    [2048] = "DEMONHUNTER",
    [4096] = "EVOKER",
}
ns.CLASS_MASKS = CLASS_MASKS

local ICONS = {
    DEMONHUNTER = 1260827,
    DRUID       = 625999,
    HUNTER      = 626000,
    MAGE        = 626001,
    MONK        = 626002,
    PALADIN     = 626003,
    PRIEST      = 626004,
    ROGUE       = 626005,
    SHAMAN      = 626006,
    WARLOCK     = 626007,
    WARRIOR     = 626008,
    DEATHKNIGHT = 135771,
    EVOKER      = 4574311,
}
ns.ICONS = ICONS

local playerClass = select(2, UnitClass("player")) or "WARRIOR"

function ns.RefreshPlayerClass()
    local _, classToken = UnitClass("player")
    if classToken then
        playerClass = classToken
    end
end

local db

function ns.InitDatabase()
    if type(EliteSetCollectionTrackerDB) ~= "table" then
        EliteSetCollectionTrackerDB = {}
    end

    db = EliteSetCollectionTrackerDB
    db.patchID = tonumber(db.patchID) or 0

    if type(db.collectedSets) ~= "table" then
        db.collectedSets = {}
    end
end

function ns.GetCollectedSets()
    return db and db.collectedSets or nil
end

local RESET_MESSAGE = "Elite Set Collection Tracker: List was reset - new Elite appearances have been added to the game."

local function IsEliteSet(set)
    return set and set.limitedTimeSet and (set.description == "Elite")
end

function ns.UpdateSets()
    if not db or not C_TransmogSets or not C_TransmogSets.GetAllSets then
        return false
    end

    local sets = C_TransmogSets.GetAllSets()
    if not sets then
        return false
    end

    local collected = db.collectedSets
    local previousValue = collected[playerClass] and true or false
    local newValue = false
    local patchID = db.patchID or 0
    local previousPatch = patchID

    for _, set in ipairs(sets) do
        if IsEliteSet(set) and set.patchID then
            if set.patchID > patchID then
                patchID = set.patchID
                wipe(collected)
                newValue = false
            end

            if set.classMask and CLASS_MASKS[set.classMask] == playerClass and set.patchID >= patchID then
                if set.collected then
                    newValue = true
                end
            end
        end
    end

    collected[playerClass] = newValue
    local patchChanged = patchID ~= previousPatch
    local valueChanged = previousValue ~= newValue
    db.patchID = patchID

    if patchChanged then
        print(RESET_MESSAGE)
    end

    return patchChanged or valueChanged
end
