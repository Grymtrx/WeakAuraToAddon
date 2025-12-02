local addonName, ns = ...

local defaultStart = time({ year = 2025, month = 1, day = 1, hour = 1 }) or 0
local defaultEnd   = time({ year = 2025, month = 12, day = 30, hour = 11 }) or (defaultStart + 86400)

local defaults = {
    startTimestamp = defaultStart,
    endTimestamp = defaultEnd,
    seasonLabel = "Season Progress",
    isProjected = false,
    autoSeasonLabel = true,
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

    local hadAutoFlag = SeasonProgressDB.autoSeasonLabel ~= nil

    CopyDefaults(SeasonProgressDB, defaults)
    db = SeasonProgressDB

    if not hadAutoFlag and db.seasonLabel and db.seasonLabel ~= "" and db.seasonLabel ~= defaults.seasonLabel then
        db.autoSeasonLabel = false
    end
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

local function TrimText(str)
    if type(str) ~= "string" then
        return nil
    end
    local trimmed = str:gsub("^%s+", "")
    trimmed = trimmed:gsub("%s+$", "")
    return trimmed
end

local function ExtractSeasonPrefix(name)
    if type(name) ~= "string" then
        return nil
    end
    local prefix = name:match("^(.-)%s+Gladiator")
    if prefix then
        prefix = TrimText(prefix)
        if prefix and prefix ~= "" then
            return prefix
        end
    end
    return nil
end

local function DetectLatestSeasonName()
    if not C_TransmogSets or not C_TransmogSets.GetAllSets then
        return nil
    end

    local sets = C_TransmogSets.GetAllSets()
    if not sets then
        return nil
    end

    local bestName
    local bestPatch = 0
    for _, setInfo in ipairs(sets) do
        if setInfo and setInfo.limitedTimeSet and setInfo.description == "Elite" then
            local prefix = ExtractSeasonPrefix(setInfo.name)
            if prefix then
                local patch = tonumber(setInfo.patchID) or 0
                if patch >= bestPatch then
                    bestPatch = patch
                    bestName = prefix
                end
            end
        end
    end
    return bestName
end

function ns.IsSeasonProjected()
    if not db then
        return defaults.isProjected
    end
    return db.isProjected and true or false
end

local function NotifyVisuals()
    if ns.UpdateSeasonVisuals then
        ns.UpdateSeasonVisuals()
    end
end

local function UpdateSeasonLabel(label, autoManaged)
    if not db or type(label) ~= "string" or label == "" then
        return false
    end

    local shouldNotify = (db.seasonLabel ~= label) or (autoManaged and db.autoSeasonLabel ~= true) or ((not autoManaged) and db.autoSeasonLabel ~= false)

    db.seasonLabel = label
    db.autoSeasonLabel = autoManaged and true or false

    if shouldNotify then
        NotifyVisuals()
    end
    return true
end

function ns.SetSeasonWindow(startTimestamp, endTimestamp, isProjected)
    if startTimestamp == nil or endTimestamp == nil then
        if db then
            db.startTimestamp = nil
            db.endTimestamp = nil
            db.isProjected = nil
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
    if isProjected == nil then
        db.isProjected = false
    else
        db.isProjected = isProjected and true or false
    end
    NotifyVisuals()
    return true
end

function ns.SetSeasonLabel(label)
    return UpdateSeasonLabel(label, false)
end

function ns.TryAutoSeasonLabel(ignoreOptOut)
    if not db then
        return false
    end
    if not ignoreOptOut and db.autoSeasonLabel == false then
        return false
    end

    local detected = DetectLatestSeasonName()
    if not detected then
        return false
    end

    UpdateSeasonLabel(detected, true)
    return true
end

function ns.EnableAutoSeasonLabel()
    if not db then
        return false
    end
    db.autoSeasonLabel = true
    if not ns.TryAutoSeasonLabel(true) then
        NotifyVisuals()
    end
    return true
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

local function ParseProjectionFlag(flag)
    if not flag or flag == "" then
        return false, true
    end
    flag = flag:lower()
    if flag == "projected" or flag == "proj" or flag == "approx" or flag == "approximate" then
        return true, true
    elseif flag == "confirmed" or flag == "confirm" then
        return false, true
    end
    return false, false
end

SLASH_SEASONPROGRESS_DATES1 = "/spd"
SlashCmdList.SEASONPROGRESS_DATES = function(msg)
    msg = (msg or ""):gsub("^%s+", "")
    if msg == "" then
        print("|cffff5555SeasonProgress: usage /spd MM-DD-YYYY MM-DD-YYYY [projected|confirmed]|r")
        print("|cffff5555SeasonProgress: or /spd clear to reset.|r")
        return
    end

    if msg == "clear" then
        ns.SetSeasonWindow(nil, nil)
        print("|cff33ff99SeasonProgress:|r season dates cleared.")
        return
    end

    local tokens = {}
    for word in msg:gmatch("%S+") do
        table.insert(tokens, word)
    end

    local startStr, endStr, flag = tokens[1], tokens[2], tokens[3]
    if not startStr or not endStr then
        print("|cffff5555SeasonProgress: usage /spd MM-DD-YYYY MM-DD-YYYY [projected|confirmed]|r")
        return
    end

    local startTime = ParseDate(startStr)
    local endTime = ParseDate(endStr)
    local isProjected, okFlag = ParseProjectionFlag(flag)
    if not okFlag then
        print("|cffff5555SeasonProgress: third value must be projected or confirmed when provided.|r")
        return
    end

    if startTime and endTime and ns.SetSeasonWindow(startTime, endTime, isProjected) then
        local label = isProjected and "projected" or "confirmed"
        print(string.format("|cff33ff99SeasonProgress:|r season window updated (%s -> %s, %s)", startStr, endStr, label))
    else
        print("|cffff5555SeasonProgress: invalid dates. Use MM-DD-YYYY MM-DD-YYYY and ensure end > start.|r")
    end
end

SLASH_SEASONPROGRESS_NAME1 = "/spn"
SlashCmdList.SEASONPROGRESS_NAME = function(msg)
    msg = (msg or ""):gsub("^%s+", "")
    if msg == "" then
        print("|cffff5555SeasonProgress: usage /spn Season Name|r")
        print("|cffff5555SeasonProgress: or /spn auto to use detected season names.|r")
        return
    end

    if msg:lower() == "auto" then
        if ns.EnableAutoSeasonLabel and ns.EnableAutoSeasonLabel() then
            print("|cff33ff99SeasonProgress:|r automatic season naming enabled.")
        else
            print("|cffff5555SeasonProgress: unable to enable automatic naming right now.|r")
        end
        return
    end

    if ns.SetSeasonLabel(msg) then
        print("|cff33ff99SeasonProgress:|r title updated.")
    else
        print("|cffff5555SeasonProgress: season name invalid.|r")
    end
end
