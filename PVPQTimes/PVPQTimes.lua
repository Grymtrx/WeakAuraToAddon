-- PvPQTimes.lua
-- Shows estimated and elapsed queue times for PvP queues in a movable frame.

-- SavedVariables table (account-wide)
PVPQTimesDB = PVPQTimesDB or {}

local FONT_SIZE   = 12
local FONT_FLAGS  = "OUTLINE"

-- Padding inside the backdrop
local PADDING_X   = 20   -- total horizontal padding (left+right)
local PADDING_Y   = 12   -- total vertical padding (top+bottom)

-- Hover hint
local HINT_TEXT   = "|cff888888Click + Drag me|r"

local baseText    = ""


local PRETTY_NAMES = {
    ["Solo Shuffle: All Arenas"]  = "Solo Shuffle: Arena",
    ["Rated Battleground Blitz"]  = "Battleground Blitz",
    ["Random Epic Battleground"]  = "Random Epic BG",
    ["Brawl: Southshore vs. Tarren Mill"] = "Brawl: SSTM",
}


-- Time Formatting
local function FormatMillisVerbose(millis)
    if not millis or millis <= 0 then
        return "0 sec"
    end

    local totalSeconds = math.floor(millis / 1000 + 0.5)
    local hours        = math.floor(totalSeconds / 3600)
    local minutes      = math.floor((totalSeconds % 3600) / 60)
    local seconds      = totalSeconds % 60

    local parts = {}

    if hours > 0 then
        table.insert(parts, string.format("%d hr", hours))
    end

    if minutes > 0 or hours > 0 then
        table.insert(parts, string.format("%d min", minutes))
    end

    -- Always show seconds
    table.insert(parts, string.format("%d sec", seconds))

    return table.concat(parts, " ")
end


-- Queue Collection
local function CollectQueues()
    local queues = {}

    local max = GetMaxBattlefieldID and GetMaxBattlefieldID() or 0
    for i = 1, max do
        local status, mapName = GetBattlefieldStatus(i)
        if status == "queued" then
            local prettyName = PRETTY_NAMES[mapName] or mapName or ("Queue " .. i)

            local avgWaitMillis = GetBattlefieldEstimatedWaitTime(i)
            local waitedMillis  = GetBattlefieldTimeWaited(i)

            table.insert(queues, {
                index   = i,
                name    = prettyName,
                avgStr  = FormatMillisVerbose(avgWaitMillis or 0),
                timeStr = FormatMillisVerbose(waitedMillis or 0),
            })
        end
    end

    return queues
end


-- UI Frame (Blizzard backdrop, dynamic size)
local frame = CreateFrame("Frame", "PVPQTimesFrame", UIParent, "BackdropTemplate")
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
frame:Hide()

-- Dark-theme Blizzard-style tooltip backdrop
frame:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true,
    tileSize = 16,
    edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
})
frame:SetBackdropColor(0, 0, 0, 0.9)              -- dark background
frame:SetBackdropBorderColor(0.15, 0.15, 0.15, 1) -- dark border

-- Movable + position saving
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

frame:SetScript("OnDragStart", function(self)
    self:StartMoving()
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, anchor, relativePoint, x, y = self:GetPoint()
    PVPQTimesDB.point = point
    PVPQTimesDB.relativePoint = relativePoint
    PVPQTimesDB.x = x
    PVPQTimesDB.y = y
end)

-- Text
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
text:SetPoint("CENTER", frame, "CENTER", 0, 0)
text:SetJustifyH("LEFT")

local font = text:GetFont()
text:SetFont(font, FONT_SIZE, FONT_FLAGS)


-- Heartbeat Animation (fade in/out)
local fadeGroup = frame:CreateAnimationGroup()

-- Fade out to 60% alpha
local fadeOut = fadeGroup:CreateAnimation("Alpha")
fadeOut:SetFromAlpha(1)
fadeOut:SetToAlpha(0.6)
fadeOut:SetDuration(0.4)
fadeOut:SetOrder(1)

-- Fade back in
local fadeIn = fadeGroup:CreateAnimation("Alpha")
fadeIn:SetFromAlpha(0.6)
fadeIn:SetToAlpha(1)
fadeIn:SetDuration(0.4)
fadeIn:SetOrder(2)

-- Pause to complete ~2s cycle
local pause = fadeGroup:CreateAnimation("Alpha")
pause:SetFromAlpha(1)
pause:SetToAlpha(1)
pause:SetDuration(1.2)
pause:SetOrder(3)

fadeGroup:SetLooping("REPEAT")

-- Only animate while frame is shown
local originalShow = frame.Show
frame.Show = function(self)
    originalShow(self)
    if not fadeGroup:IsPlaying() then
        fadeGroup:Play()
    end
end

local originalHide = frame.Hide
frame.Hide = function(self)
    originalHide(self)
    if fadeGroup:IsPlaying() then
        fadeGroup:Stop()
    end
end


-- Helper: resize frame to current text
local function ResizeToCurrentText()
    local textWidth  = text:GetStringWidth()  or 0
    local textHeight = text:GetStringHeight() or 0

    local frameWidth  = textWidth  + PADDING_X
    local frameHeight = textHeight + PADDING_Y

    frame:SetSize(frameWidth, frameHeight)
end


-- Hover hint behavior
frame:SetScript("OnEnter", function(self)
    if baseText and baseText ~= "" then
        text:SetText(baseText .. "\n" .. HINT_TEXT)
        ResizeToCurrentText()
    end
end)

frame:SetScript("OnLeave", function(self)
    if baseText and baseText ~= "" then
        text:SetText(baseText)
        ResizeToCurrentText()
    end
end)


-- State & Update Logic
local hasQueues      = false
local updateThrottle = 0
local UPDATE_INTERVAL = 0.25

local function UpdateDisplay()
    local queues = CollectQueues()

    if #queues == 0 then
        hasQueues = false
        frame:Hide()
        baseText = ""
        return
    end

    hasQueues = true
    frame:Show()

    -- Build multi-queue text block
    local lines = {}

    for idx, q in ipairs(queues) do
        -- Blizzard yellow for the title
        local header = string.format("|cffffd100%s|r", q.name)

        table.insert(lines, header)
        table.insert(lines, "Avg: " .. q.avgStr)
        table.insert(lines, "In Q: " .. q.timeStr)

        if idx < #queues then
            table.insert(lines, "") -- blank line between queues
        end
    end

    baseText = table.concat(lines, "\n")

    -- If currently hovered, keep the hint visible
    if frame:IsMouseOver() then
        text:SetText(baseText .. "\n" .. HINT_TEXT)
    else
        text:SetText(baseText)
    end

    ResizeToCurrentText()
end


-- Events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        -- Restore saved position if it exists
        if PVPQTimesDB.point then
            frame:ClearAllPoints()
            frame:SetPoint(
                PVPQTimesDB.point,
                UIParent,
                PVPQTimesDB.relativePoint or PVPQTimesDB.point,
                PVPQTimesDB.x or 0,
                PVPQTimesDB.y or 0
            )
        end

        -- Initial check if already in any queues
        UpdateDisplay()
    elseif event == "UPDATE_BATTLEFIELD_STATUS" then
        UpdateDisplay()
    end
end)

frame:SetScript("OnUpdate", function(self, elapsed)
    if not hasQueues then
        return
    end

    updateThrottle = updateThrottle + elapsed
    if updateThrottle < UPDATE_INTERVAL then
        return
    end
    updateThrottle = 0

    UpdateDisplay()
end)
