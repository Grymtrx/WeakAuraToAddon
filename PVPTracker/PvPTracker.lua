local ADDON_NAME = ...
local tracker = CreateFrame("Frame")

local CURRENT_VERSION = 1
local CONQUEST_CURRENCY_ID = 1602
local DATA_DELAY_SECONDS = 8
local STALE_DATA_SECONDS = 30 * 24 * 60 * 60
local ROW_HEIGHT = 20
local COLUMN_PADDING = 10
local DEBUG_LOGGING = false

local GetDungeonScoreRarityColor = C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor

local trackedBrackets = {
    { key = "ratingSolo", label = "Solo", bracket = 7, iconField = "tierIconIDSolo", perSpec = true },
    { key = "rating2v2", label = "2v2", bracket = 1, iconField = "tierIconID2v2" },
    { key = "rating3v3", label = "3v3", bracket = 2, iconField = "tierIconID3v3" },
}

local columns = {
    { key = "name", label = "Character", width = 170, justify = "LEFT" },
}

for _, bracket in ipairs(trackedBrackets) do
    table.insert(columns, {
        key = bracket.key,
        label = bracket.label,
        width = bracket.key == "ratingSolo" and 260 or 90,
        justify = bracket.key == "ratingSolo" and "LEFT" or "CENTER",
        iconField = bracket.iconField,
    })
end

table.insert(columns, {
    key = "conquestOwned",
    label = "Conquest",
    width = 140,
    justify = "CENTER",
})

local columnOffsets = {}
local BASE_TOTAL_COLUMN_WIDTH = 0
do
    local offset = 0
    for index, info in ipairs(columns) do
        columnOffsets[index] = offset
        offset = offset + info.width + COLUMN_PADDING
    end
    BASE_TOTAL_COLUMN_WIDTH = math.max(offset - COLUMN_PADDING, 0)
end

local sortOptions = {
    { key = "ratingSolo", label = "Solo Shuffle" },
    { key = "rating3v3", label = "3v3" },
    { key = "rating2v2", label = "2v2" },
    { key = "conquestOwned", label = "Conquest" },
}

local function safeCurrencyInfo(currencyID)
    local info = C_CurrencyInfo.GetCurrencyInfo(currencyID)
    if not info then
        return {
            quantity = 0,
            totalEarned = 0,
            iconFileID = 0,
            maxQuantity = 0,
        }
    end
    return info
end

local function cleanDatabase(db)
    if not db.characters then
        db.characters = {}
        return
    end

    local now = time()
    for key, data in pairs(db.characters) do
        if type(data) ~= "table" then
            db.characters[key] = nil
        elseif not data.version or data.version ~= CURRENT_VERSION then
            db.characters[key] = nil
        elseif not data.timestamp or (now - data.timestamp) > STALE_DATA_SECONDS then
            db.characters[key] = nil
        end
    end
end

local function initDatabase()
    if not PvPTrackerDB then
        PvPTrackerDB = {}
    end

    PvPTrackerDB.version = CURRENT_VERSION
    PvPTrackerDB.characters = PvPTrackerDB.characters or {}
    PvPTrackerDB.sortKey = PvPTrackerDB.sortKey or "ratingSolo"

    cleanDatabase(PvPTrackerDB)

    return PvPTrackerDB
end

local function characterKey()
    local name = UnitName("player")
    local realm = GetRealmName()
    if not name or not realm then
        return nil
    end
    return name .. "-" .. realm
end

local function classColorString(classFile)
    local colorInfo = classFile and RAID_CLASS_COLORS[classFile]
    return colorInfo and colorInfo.colorStr or "FFFFFFFF"
end

local function shortRealmName(realm)
    if not realm or realm == "" then
        return ""
    end
    return realm:sub(1, 5)
end

local function formatCharacterName(record)
    if not record.name then
        return "Unknown"
    end

    local color = record.classColor or "FFFFFFFF"
    local displayName = record.name
    if record.realm and record.realm ~= GetRealmName() then
        local realmShort = shortRealmName(record.realm)
        if realmShort ~= "" then
            displayName = displayName .. "-" .. realmShort
        end
    end

    if record.specIcon then
        return ("|c%s|T%d:14|t %s|r"):format(color, record.specIcon, displayName)
    end

    return ("|c%s%s|r"):format(color, displayName)
end

local function formatRatingColored(rating)
    rating = rating or 0
    if rating <= 0 then
        return "-"
    end

    if rating >= 2700 then
        return ("|cff00ccff%d|r"):format(rating)
    end

    if GetDungeonScoreRarityColor then
        local color = GetDungeonScoreRarityColor(rating)
        if color then
            return color:WrapTextInColorCode(("%d"):format(rating))
        end
    end

    return tostring(rating)
end

local db
local playerKey

local function updateSoloAggregates(record)
    if not record then
        return
    end

    local bestRating = 0
    local bestTier
    local bestSpecIcon

    if record.soloRatings then
        for _, entry in pairs(record.soloRatings) do
            local rating = entry.rating or 0
            if rating > bestRating then
                bestRating = rating
                bestTier = entry.tierIconID
                bestSpecIcon = entry.specIcon
            end
        end
    end

    record.ratingSolo = bestRating
    record.tierIconIDSolo = bestTier
    record.bestSoloSpecIcon = bestSpecIcon
end

function tracker:GetColumnText(data, columnInfo)
    if columnInfo.key == "name" then
        return formatCharacterName(data)
    elseif columnInfo.key == "conquestOwned" then
        return formatConquest(data, self.conquestIcon or 0)
    elseif columnInfo.key == "ratingSolo" then
        return formatSoloRatings(data)
    else
        return formatRating(data, columnInfo)
    end
end

function tracker:ApplyRowLayout(row)
    if not row or not row.textWidgets then
        return
    end
    for index, text in ipairs(row.textWidgets) do
        local offset = columnOffsets[index] or 0
        local width = columns[index].width
        text:ClearAllPoints()
        text:SetPoint("LEFT", row, "LEFT", offset, 0)
        text:SetWidth(width)
    end
end

function tracker:UpdateAllRowsLayout()
    if not self.rows then
        return
    end
    for _, row in ipairs(self.rows) do
        self:ApplyRowLayout(row)
    end
end

function tracker:InitializeColumnLayout()
    self.totalColumnWidth = BASE_TOTAL_COLUMN_WIDTH

    if self.headerLabels then
        for index, label in ipairs(self.headerLabels) do
            local offset = columnOffsets[index] or 0
            label:ClearAllPoints()
            label:SetPoint("BOTTOMLEFT", self.header, "BOTTOMLEFT", offset, 4)
            label:SetWidth(columns[index].width)
        end
    end

    if self.scrollChild then
        self.scrollChild:SetWidth(self.totalColumnWidth)
    end

    if self.frame then
        local minWidth = 720
        self.frame:SetWidth(math.max(minWidth, self.totalColumnWidth + 60))
    end

    self:UpdateAllRowsLayout()
end

local function debugPrint(...)
    if not DEBUG_LOGGING then
        return
    end
    local prefix = "|cff33ff99PvP Tracker|r"
    print(prefix, ...)
end

local function ensureRecord()
    if not db then
        debugPrint("ensureRecord aborted: database not ready")
        return nil
    end

    playerKey = playerKey or characterKey()
    if not playerKey then
        debugPrint("ensureRecord aborted: missing player key")
        return nil
    end

    local record = db.characters[playerKey]
    if not record then
        record = {}
        db.characters[playerKey] = record
        debugPrint("Created new record", playerKey)
    else
        debugPrint("Updating record", playerKey)
    end

    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or ""
    local _, classFile = UnitClass("player")
    local specID = GetSpecialization()
    local specIcon
    if specID then
        local _, _, _, icon = GetSpecializationInfo(specID)
        specIcon = icon
    end

    record.name = name
    record.realm = realm
    record.classFile = classFile
    record.classColor = classColorString(classFile)
    record.specID = specID
    record.specIcon = specIcon
    record.key = playerKey
    record.timestamp = time()
    record.version = CURRENT_VERSION
    record.weeklyreset = time() + (C_DateAndTime.GetSecondsUntilWeeklyReset() or 0)

    record.soloRatings = record.soloRatings or {}

    if record.ratingSolo and (not next(record.soloRatings)) then
        local entryKey = record.SpecIDSolo or specID or "default"
        record.soloRatings[entryKey] = {
            rating = record.ratingSolo,
            tierIconID = record.tierIconIDSolo,
            specIndex = entryKey,
            specIcon = record.specIcon,
        }
    end

    updateSoloAggregates(record)
    debugPrint("Record updated", playerKey, "specID:", specID, "class:", classFile)
    return record
end

local function formatRating(record, columnInfo)
    local rating = record[columnInfo.key]
    if columnInfo.key == "ratingSolo" then
        return formatSoloRatings(record)
    end
    return formatRatingColored(rating)
end

local function formatSoloRatings(record)
    if not record.soloRatings or not next(record.soloRatings) then
        return "-"
    end

    local entries = {}
    for specIndex, info in pairs(record.soloRatings) do
        table.insert(entries, {
            specIndex = specIndex,
            rating = info.rating or 0,
            tierIconID = info.tierIconID,
            specIcon = info.specIcon,
        })
    end

    table.sort(entries, function(a, b)
        if a.rating ~= b.rating then
            return a.rating > b.rating
        end
        return (a.specIndex or 0) < (b.specIndex or 0)
    end)

    local parts = {}
    for _, value in ipairs(entries) do
        local specIcon = value.specIcon or 0
        local ratingText = formatRatingColored(value.rating or 0)
        local specTexture = specIcon > 0 and ("|T%d:16|t "):format(specIcon) or ""
        table.insert(parts, specTexture .. ratingText)
    end

    return table.concat(parts, "   ")
end

local function formatConquest(record, iconID)
    local owned = record.conquestOwned or 0
    local earned = record.conquestEarned or 0
    local maxQty = record.maxConquest or 0

    if maxQty > 0 then
        local remaining = math.max(maxQty - earned, 0)
        if remaining > 0 then
            return ("|T%d:14|t %d (%d left)"):format(iconID or 0, owned, remaining)
        end
    end

    if iconID and iconID > 0 then
        return ("|T%d:14|t %d"):format(iconID, owned)
    end

    return tostring(owned)
end

local function attachDrag(frame)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
end

function tracker:CreateUI()
    if self.frame then
        return
    end

    local frame = CreateFrame("Frame", "PvPTrackerFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(720, 420)
    frame:SetPoint("CENTER")
    frame:Hide()
    attachDrag(frame)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
    frame.title:SetText("PvP Tracker")

    local header = CreateFrame("Frame", nil, frame)
    header:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -32)
    header:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -32)
    header:SetHeight(44)

    self.header = header
    self.headerLabels = {}

    for index, columnInfo in ipairs(columns) do
        local label = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetJustifyH(columnInfo.justify or "LEFT")
        label:SetText(columnInfo.label)
        self.headerLabels[index] = label
    end

    local dropdown = CreateFrame("Frame", "PvPTrackerSortDropdown", header, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPRIGHT", header, "TOPRIGHT", -4, -4)
    self.sortDropdown = dropdown

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -30, 10)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    scrollChild:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", -20, 0)
    scrollChild:SetHeight(scrollFrame:GetHeight())
    scrollChild:SetWidth(scrollFrame:GetWidth())

    scrollFrame:SetScrollChild(scrollChild)

    self.frame = frame
    self.scrollFrame = scrollFrame
    self.scrollChild = scrollChild
    self.rows = {}
    self.sortedRecords = {}

    local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    footer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 12)
    footer:SetText("Total Conquest: 0")
    self.totalConquestText = footer

    scrollFrame:HookScript("OnSizeChanged", function(_, _, height)
        if tracker.totalColumnWidth then
            local width = math.max(tracker.totalColumnWidth, tracker.scrollFrame:GetWidth())
            scrollChild:SetWidth(width)
        end
        local rowCount = tracker.sortedRecords and #tracker.sortedRecords or 0
        scrollChild:SetHeight(math.max(height or scrollChild:GetHeight(), rowCount * ROW_HEIGHT))
        tracker:RefreshUI(true)
    end)

    frame:SetScript("OnShow", function()
        tracker:RefreshUI(true)
    end)

    self:InitializeColumnLayout()
    self:InitializeSortDropdown()
end

local function ensureRowWidgets(row)
    row.textWidgets = row.textWidgets or {}
    for colIndex, columnInfo in ipairs(columns) do
        if not row.textWidgets[colIndex] then
            local text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:SetJustifyH(columnInfo.justify or "LEFT")
            row.textWidgets[colIndex] = text
        end
    end
end

function tracker:AcquireRow(index)
    local row = self.rows[index]
    debugPrint("AcquireRow call", index, row and "existing" or "new")
    if not row then
        row = CreateFrame("Frame", nil, self.scrollChild)
        row:SetHeight(ROW_HEIGHT)
        self.rows[index] = row
        debugPrint("AcquireRow created", index)
    end

    ensureRowWidgets(row)
    self:ApplyRowLayout(row)
    return row
end

local function validRecord(data)
    if type(data) ~= "table" then
        debugPrint("Record invalid: not a table")
        return false
    end
    if not data.name or not data.realm then
        debugPrint("Record invalid: missing name/realm")
        return false
    end
    if data.version ~= CURRENT_VERSION then
        debugPrint("Record invalid: version mismatch")
        return false
    end
    if data.timestamp and (time() - data.timestamp) > STALE_DATA_SECONDS then
        debugPrint("Record invalid: stale timestamp")
        return false
    end
    return true
end

function tracker:GetSortValue(record)
    local key = self.sortKey or "ratingSolo"
    if key == "conquestOwned" then
        return record.conquestOwned or 0
    end
    return record[key] or 0
end

function tracker:GetSortedRecords()
    if not db or not db.characters then
        debugPrint("GetSortedRecords: database not ready")
        return {}
    end

    ensureRecord()

    wipe(self.sortedRecords)
    for _, data in pairs(db.characters) do
        if validRecord(data) then
            table.insert(self.sortedRecords, data)
        else
            debugPrint("Skipping invalid record during sort")
        end
    end
    debugPrint("SortedRecords count", #self.sortedRecords)
    if DEBUG_LOGGING then
        for _, rec in ipairs(self.sortedRecords) do
            debugPrint("Record:", rec.name, rec.realm, rec.conquestOwned, rec.ratingSolo, rec.rating2v2, rec.rating3v3)
        end
    end

    local selfRef = self
    table.sort(self.sortedRecords, function(a, b)
        local aVal = selfRef:GetSortValue(a)
        local bVal = selfRef:GetSortValue(b)
        if aVal ~= bVal then
            return aVal > bVal
        end
        return (a.name or "") < (b.name or "")
    end)

    return self.sortedRecords
end

function tracker:PopulateRow(row, data)
    debugPrint("PopulateRow start", data.name)
    for index, columnInfo in ipairs(columns) do
        local textWidget = row.textWidgets[index]
        textWidget:SetJustifyH(columnInfo.justify or "LEFT")
        local val = self:GetColumnText(data, columnInfo)
        textWidget:SetText(val)
        debugPrint("PopulateRow", index, columnInfo.key, val)
    end
end

function tracker:RefreshUI(force)
    if not self.frame or (not force and not self.dirty) then
        return
    end

    local records = self:GetSortedRecords()
    debugPrint("RefreshUI - records to draw:", #records, "dirty:", self.dirty, "force:", force)
    self:InitializeColumnLayout()
    local scrollChildHeight = math.max(#records * ROW_HEIGHT, self.scrollFrame:GetHeight())
    self.scrollChild:SetHeight(scrollChildHeight)

    local totalConq = 0
    for index, data in ipairs(records) do
        debugPrint("Render row", index, data.name)
        local row = self:AcquireRow(index)
        row:Show()
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
        row:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", 0, -(index - 1) * ROW_HEIGHT)
        self:PopulateRow(row, data)
        totalConq = totalConq + (data.conquestOwned or 0)
    end

    for index = #records + 1, #self.rows do
        self.rows[index]:Hide()
    end

    if self.totalConquestText then
        self.totalConquestText:SetText(string.format("Total Conquest: %d", totalConq))
    end

    self.dirty = false
end

function tracker:MarkDirty()
    self.dirty = true
    debugPrint("MarkDirty called - frame shown:", self.frame and self.frame:IsShown())
    if self.frame and self.frame:IsShown() then
        self:RefreshUI(true)
    end
end

function tracker:GetSortLabel(key)
    for _, option in ipairs(sortOptions) do
        if option.key == key then
            return option.label
        end
    end
    return "Sort"
end

function tracker:SetSortKey(key)
    self.sortKey = key
    if PvPTrackerDB then
        PvPTrackerDB.sortKey = key
    end
    if self.sortDropdown then
        UIDropDownMenu_SetText(self.sortDropdown, self:GetSortLabel(key))
    end
    self:MarkDirty()
end

function tracker:InitializeSortDropdown()
    if not self.sortDropdown then
        return
    end
    UIDropDownMenu_SetWidth(self.sortDropdown, 150)
    UIDropDownMenu_Initialize(self.sortDropdown, function(_, level)
        if not level then
            return
        end
        for _, option in ipairs(sortOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.func = function()
                tracker:SetSortKey(option.key)
            end
            info.checked = (self.sortKey == option.key)
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    UIDropDownMenu_SetText(self.sortDropdown, self:GetSortLabel(self.sortKey or "ratingSolo"))
end

function tracker:UpdateProgress()
    local record = ensureRecord()
    if not record then
        debugPrint("UpdateProgress aborted, missing record")
        return
    end

    local currencyInfo = safeCurrencyInfo(CONQUEST_CURRENCY_ID)
    record.conquestOwned = currencyInfo.quantity or 0
    record.conquestEarned = currencyInfo.totalEarned or 0
    record.maxConquest = currencyInfo.maxQuantity or 0
    record.timestamp = time()
    record.conquestIcon = currencyInfo.iconFileID
    record.weeklyreset = time() + (C_DateAndTime.GetSecondsUntilWeeklyReset() or 0)

    self.conquestIcon = currencyInfo.iconFileID
    debugPrint("UpdateProgress: owned", record.conquestOwned, "earned", record.conquestEarned, "max", record.maxConquest)
    self:MarkDirty()
end

function tracker:UpdateRatings()
    local record = ensureRecord()
    if not record then
        debugPrint("UpdateRatings aborted, missing record")
        return
    end

    for _, bracket in ipairs(trackedBrackets) do
        local rating, _, _, _, _, _, _, _, _, tier = GetPersonalRatedInfo(bracket.bracket)
        local tierIcon
        if tier then
            local tierInfo = C_PvP.GetPvpTierInfo(tier)
            tierIcon = tierInfo and tierInfo.tierIconID or nil
        end

        if bracket.perSpec then
            local specIndex = GetSpecialization()
            if specIndex then
                local _, _, _, specIcon = GetSpecializationInfo(specIndex)
                record.soloRatings = record.soloRatings or {}
                record.soloRatings[specIndex] = {
                    rating = rating or 0,
                    tierIconID = tierIcon,
                    specIndex = specIndex,
                    specIcon = specIcon,
                }
                updateSoloAggregates(record)
            end
        else
            record[bracket.key] = rating or 0
            record[bracket.iconField] = tierIcon
        end

        debugPrint("UpdateRatings:", bracket.label, "rating", rating, "tier", tierIcon)
    end

    record.timestamp = time()
    self:MarkDirty()
end

function tracker:RefreshAllData()
    debugPrint("RefreshAllData invoked")
    self:UpdateProgress()
    self:UpdateRatings()
end

function tracker:Toggle()
    self:CreateUI()
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self.frame:Show()
    end
end

local function handleSlash()
    debugPrint("Slash command executed")
    tracker:Toggle()
end

SLASH_PVPTRACKER1 = "/pvptracker"
SLASH_PVPTRACKER2 = "/pvptrack"
SlashCmdList.PVPTRACKER = handleSlash

tracker:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName ~= ADDON_NAME then
            return
        end

        debugPrint("ADDON_LOADED for", addonName)
        db = initDatabase()
        ensureRecord()
        self.sortKey = PvPTrackerDB.sortKey or "ratingSolo"
        print("|cff33ff99PvP Tracker|r loaded. Type /pvptracker to open the tracker window.")
        self:CreateUI()
        self:RegisterEvent("PLAYER_LOGIN")
        self:RegisterEvent("PLAYER_LOGOUT")
        self:RegisterEvent("PVP_RATED_STATS_UPDATE")
        self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
        self:RegisterEvent("WEEKLY_REWARDS_UPDATE")
        self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

    elseif event == "PLAYER_LOGIN" then
        debugPrint("PLAYER_LOGIN received")
        tracker:RefreshAllData()

    elseif event == "PLAYER_LOGOUT" then
        debugPrint("PLAYER_LOGOUT received")
        tracker:UpdateProgress()
        tracker:UpdateRatings()

    elseif event == "PVP_RATED_STATS_UPDATE" then
        debugPrint("PVP_RATED_STATS_UPDATE event")
        tracker:UpdateRatings()

    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        local currencyID = ...
        debugPrint("CURRENCY_DISPLAY_UPDATE", currencyID)
        if currencyID == nil or currencyID == CONQUEST_CURRENCY_ID then
            tracker:UpdateProgress()
        end

    elseif event == "WEEKLY_REWARDS_UPDATE" then
        debugPrint("WEEKLY_REWARDS_UPDATE event")
        tracker:UpdateProgress()

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        if unit == "player" then
            debugPrint("PLAYER_SPECIALIZATION_CHANGED")
            ensureRecord()
            tracker:UpdateRatings()
        end
    end
end)

tracker:RegisterEvent("ADDON_LOADED")
