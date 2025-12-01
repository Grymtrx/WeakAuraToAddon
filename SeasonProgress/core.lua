local addonName, ns = ...

local defaultStart = time({ year = 2025, month = 1, day = 1, hour = 1 }) or 0
local defaultEnd   = time({ year = 2025, month = 12, day = 30, hour = 11 }) or (defaultStart + 86400)

local defaults = {
    startTimestamp = defaultStart,
    endTimestamp = defaultEnd,
    seasonLabel = "Season Progress",
}

local db

local function CopyDefaults(target, source)
    for k, v in pairs(source) do
        if target[k] == nil then
            if type(v) == "table" then
                target[k] = CopyDefaults({}, v)
            else
                target[k] = v
            end
        elseif type(v) == "table" then
            CopyDefaults(target[k], v)
        end
    end
    return target
end

function ns.InitDatabase()
    if type(SeasonProgressDB) ~= "table" then
        SeasonProgressDB = {}
    end

    CopyDefaults(SeasonProgressDB, defaults)
    db = SeasonProgressDB
end

function ns.GetSeasonWindow()
    if not db then
        return defaults.startTimestamp, defaults.endTimestamp
    end
    return db.startTimestamp, db.endTimestamp
end

function ns.GetSeasonLabel()
    return (db and db.seasonLabel) or defaults.seasonLabel
end

local function NotifyVisuals()
    if ns.UpdateSeasonVisuals then
        ns.UpdateSeasonVisuals()
    end
end

function ns.SetSeasonWindow(startTimestamp, endTimestamp)
    if startTimestamp == nil or endTimestamp == nil then
        if db then
            db.startTimestamp = nil
            db.endTimestamp = nil
            NotifyVisuals()
        end
        return true
    end

    if not db or type(startTimestamp) ~= "number" or type(endTimestamp) ~= "number" then
        return false
    end
    if endTimestamp <= startTimestamp then
        return false
    end

    db.startTimestamp = startTimestamp
    db.endTimestamp = endTimestamp
    NotifyVisuals()
    return true
end

function ns.SetSeasonLabel(label)
    if not db then
        return
    end
    if type(label) == "string" and label ~= "" then
        db.seasonLabel = label
        NotifyVisuals()
    end
end

local function ParseDate(str)
    if type(str) ~= "string" then
        return nil
    end
    local month, day, year = str:match("^(%d%d)%-(%d%d)%-(%d%d%d%d)$")
    month, day, year = tonumber(month), tonumber(day), tonumber(year)
    if not year or not month or not day then
        return nil
    end
    return time({ year = year, month = month, day = day, hour = 10 }) -- midday default
end

SLASH_SEASONPROGRESS_DATES1 = "/spd"
SlashCmdList.SEASONPROGRESS_DATES = function(msg)
    msg = (msg or ""):gsub("^%s+", "")
    if msg == "" then
        print("|cffff5555SeasonProgress: usage /spd MM-DD-YYYY MM-DD-YYYY|r")
        print("|cffff5555SeasonProgress: or /spd clear to reset.|r")
        return
    end

    if msg == "clear" then
        ns.SetSeasonWindow(nil, nil)
        print("|cff33ff99SeasonProgress:|r season dates cleared.")
        return
    end

    local startStr, endStr = msg:match("^(%S+)%s+(%S+)")
    if not startStr or not endStr then
        print("|cffff5555SeasonProgress: usage /spd MM-DD-YYYY MM-DD-YYYY|r")
        return
    end

    local startTime = ParseDate(startStr)
    local endTime = ParseDate(endStr)
    if startTime and endTime and ns.SetSeasonWindow(startTime, endTime) then
        print(string.format("|cff33ff99SeasonProgress:|r season window updated (%s -> %s)", startStr, endStr))
    else
        print("|cffff5555SeasonProgress: invalid dates. Use MM-DD-YYYY MM-DD-YYYY and ensure end > start.|r")
    end
end

SLASH_SEASONPROGRESS_NAME1 = "/spn"
SlashCmdList.SEASONPROGRESS_NAME = function(msg)
    msg = (msg or ""):gsub("^%s+", "")
    if msg == "" then
        print("|cffff5555SeasonProgress: usage /spn Season Name|r")
        return
    end
    ns.SetSeasonLabel(msg)
    print("|cff33ff99SeasonProgress:|r title updated.")
end
