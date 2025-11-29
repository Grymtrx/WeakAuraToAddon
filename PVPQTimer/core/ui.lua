local ADDON_NAME, NS = ...

--------------------------------------------------
-- QPopCV Copy URL Dialog
--------------------------------------------------
local function CreateCopyUrlDialog()
    local f = CreateFrame("Frame", "PVPQTimerCopyUrlFrame", UIParent, "BackdropTemplate")
    f:SetSize(360, 90)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile     = true, tileSize = 32, edgeSize = 32,
        insets   = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:Hide()

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOP", 0, -12)
    title:SetText("QPopCV Link")

    -- EditBox
    local eb = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
    eb:SetAutoFocus(false)
    eb:SetSize(300, 20)
    eb:SetPoint("TOP", title, "BOTTOM", 0, -8)
    eb:SetText("") -- will be filled when shown
    eb:SetCursorPosition(0)

    -- OK / Close button
    local ok = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    ok:SetSize(80, 22)
    ok:SetPoint("BOTTOM", 0, 10)
    ok:SetText(OKAY)

    ok:SetScript("OnClick", function()
        f:Hide()
    end)

    -- Simple ESC handling
    f:SetScript("OnKeyDown", function(self, key)
        if key == "ESCAPE" then
            self:SetPropagateKeyboardInput(false)
            self:Hide()
        else
            self:SetPropagateKeyboardInput(true)
        end
    end)

    -- Expose what we need
    f.editBox = eb
    return f
end

local CopyUrlDialog = CreateCopyUrlDialog()

-- Helper to show + prepare dialog
function NS.ShowCopyUrlDialog()
    if not CopyUrlDialog then return end

    local eb = CopyUrlDialog.editBox
    if not eb then return end

    -- 🔥 Hard-coded URL here
    local url = "https://discord.gg/KpupS6N3Zj"

    CopyUrlDialog:Show()
    CopyUrlDialog:Raise()

    eb:SetText(url)
    eb:HighlightText()
    eb:SetFocus()
end


--------------------------------------------------
-- Create Frame
--------------------------------------------------
local frame = CreateFrame("Frame", "PVPQTimerFrame", UIParent, "BackdropTemplate")
NS.frame = frame

-- Restore account-wide position immediately if we already have one
if NS.global and NS.global.point then
    frame:ClearAllPoints()
    frame:SetPoint(
        NS.global.point,
        UIParent,
        NS.global.relativePoint or NS.global.point,
        NS.global.x or 0,
        NS.global.y or 0
    )
end

frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
frame:Hide()

-- Default backdrop definition so we can reuse it when toggling
local DEFAULT_BACKDROP = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true, tileSize = 16, edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
}

-- Start with backdrop ON by default
frame:SetBackdrop(DEFAULT_BACKDROP)
frame:SetBackdropColor(0, 0, 0, 0.75)
frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

frame:SetClampedToScreen(true)
frame:SetFrameStrata("MEDIUM")
frame:SetFrameLevel(10)

--------------------------------------------------
-- Runtime background toggle
--------------------------------------------------
function NS.ApplyBackgroundEnabled(enabled)
    -- treat nil as "true by default"
    if enabled == nil then
        enabled = true
    end

    -- Make sure SavedVariables exist; keep NS in sync
    PVPQTimerDB = PVPQTimerDB or {}
    PVPQTimerDB.global = PVPQTimerDB.global or {}

    NS.db     = PVPQTimerDB
    NS.global = PVPQTimerDB.global

    NS.global.enableBackground = enabled

    if enabled then
        frame:SetBackdrop(DEFAULT_BACKDROP)
        frame:SetBackdropColor(0, 0, 0, 0.75)
        frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    else
        -- strip background & border
        frame:SetBackdrop(nil)
    end
end

--------------------------------------------------
-- Dragging / position save (account-wide)
--------------------------------------------------
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()

    -- Get center of frame and UIParent
    local fX, fY = self:GetCenter()
    local uX, uY = UIParent:GetCenter()

    if not (fX and fY and uX and uY) then
        return
    end

    -- Offset from center
    local x = fX - uX
    local y = fY - uY

    -- Ensure SavedVariables root exists
    PVPQTimerDB = PVPQTimerDB or {}
    PVPQTimerDB.global = PVPQTimerDB.global or {}

    -- Always save as CENTER anchor
    PVPQTimerDB.global.point         = "CENTER"
    PVPQTimerDB.global.relativePoint = "CENTER"
    PVPQTimerDB.global.x             = x
    PVPQTimerDB.global.y             = y

    -- Keep NS in sync
    NS.db     = PVPQTimerDB
    NS.global = PVPQTimerDB.global
end)


--------------------------------------------------
-- Text
--------------------------------------------------
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
NS.text = text
text:SetJustifyH("LEFT")
text:SetPoint("CENTER")

do
    local font, size, flags = text:GetFont()
    local targetSize = (NS.global and NS.global.fontSize) or NS.FONT_SIZE or size
    text:SetFont(font, targetSize, NS.FONT_FLAGS or flags)
end


--------------------------------------------------
-- Runtime font-size application
--------------------------------------------------
function NS.ApplyFontSize(newSize)
    if type(newSize) ~= "number" or newSize <= 0 then
        return
    end

    -- Ensure SavedVariables and global settings exist
    PVPQTimerDB = PVPQTimerDB or {}
    PVPQTimerDB.global = PVPQTimerDB.global or {}

    NS.db     = PVPQTimerDB
    NS.global = PVPQTimerDB.global

    -- Persist and mirror to constants
    NS.global.fontSize = newSize
    NS.FONT_SIZE       = newSize

    -- Apply to live fontstring
    if NS.text then
        local font, _, flags = NS.text:GetFont()
        NS.text:SetFont(font, newSize, NS.FONT_FLAGS or flags)
    end

    -- Resize frame so background fits new text size
    if NS.Resize then
        NS.Resize()
    end
end

--------------------------------------------------
-- Heartbeat Animation
--------------------------------------------------
local function CreateHeartbeatAnimation(parent)
    local group = parent:CreateAnimationGroup()
    group:SetLooping("REPEAT")

    local fadeOut = group:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0.6)
    fadeOut:SetDuration(0.4)
    fadeOut:SetOrder(1)

    local fadeIn = group:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.6)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.4)
    fadeIn:SetOrder(2)

    local hold = group:CreateAnimation("Alpha")
    hold:SetFromAlpha(1)
    hold:SetToAlpha(1)
    hold:SetDuration(1.2)
    hold:SetOrder(3)

    return group
end

local heartbeatGroup = CreateHeartbeatAnimation(frame)

-- Only run the animation while visible
local Original_Show = frame.Show
function frame:Show()
    Original_Show(self)
    if not heartbeatGroup:IsPlaying() then
        heartbeatGroup:Play()
    end
end

local Original_Hide = frame.Hide
function frame:Hide()
    Original_Hide(self)
    if heartbeatGroup:IsPlaying() then
        heartbeatGroup:Stop()
    end
end

--------------------------------------------------
-- Size helpers
--------------------------------------------------
local function Resize()
    local w = text:GetStringWidth()  or 0
    local h = text:GetStringHeight() or 0
    frame:SetSize(w + (NS.PADDING_X or 20), h + (NS.PADDING_Y or 12))
end
NS.Resize = Resize

--------------------------------------------------
-- Pause ("II") button
--------------------------------------------------
local pauseButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
NS.pauseButton = pauseButton
pauseButton:SetSize(21, 21)
pauseButton:SetPoint("LEFT", frame, "RIGHT", 4, 0)
pauseButton:SetText("II")
pauseButton:GetFontString():SetFontObject("GameFontNormalSmall")
pauseButton:Hide()

pauseButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Pause Queue", 1, 0.82, 0)
    GameTooltip:AddLine(
        "Save / hold your spot in PvP queues by entering a follower dungeon.\n\n"
        .. "1. Click this button.\n"
        .. "2. Queue for any follower dungeon.\n"
        .. "3. Enter the dungeon to pause your PvP queues.",
        1, 1, 1, true
    )
    GameTooltip:Show()
end)

pauseButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

pauseButton:SetScript("OnClick", function()
    -- Open the PvE / Group Finder frame so the player can select a follower dungeon.
    if PVEFrame and PVEFrame:IsShown() then
        HideUIPanel(PVEFrame)
    else
        PVEFrame_ToggleFrame("GroupFinderFrame")
    end
end)

--------------------------------------------------
-- Pause button config (enable + location)
--------------------------------------------------
function NS.ApplyPauseButtonConfig()
    if not NS.pauseButton then return end

    local g = NS.global or {}

    -- Default: enabled unless explicitly false
    local enabled = g.enablePauseButton
    if enabled == nil then
        enabled = true
    end
    NS.pauseButtonEnabled = enabled

    -- Anchor left or right of the frame
    local loc = g.pauseLocation or "RIGHT"

    pauseButton:ClearAllPoints()
    if loc == "LEFT" then
        -- Left side of the backdrop
        pauseButton:SetPoint("RIGHT", frame, "LEFT", -4, 0)
    else
        -- Right side (default behavior)
        pauseButton:SetPoint("LEFT", frame, "RIGHT", 4, 0)
    end

    -- Don’t force-show here; UpdateDisplay decides based on queues.
    if not enabled then
        pauseButton:Hide()
    end
end

--------------------------------------------------
-- Copy URL button (for "Queue Expired" banner)
--------------------------------------------------
local copyButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
NS.copyButton = copyButton
copyButton:SetSize(80, 18)
copyButton:SetPoint("TOP", frame, "BOTTOM", 0, -2)
copyButton:SetText("Copy Url")
copyButton:GetFontString():SetFontObject("GameFontNormalSmall")
copyButton:Hide()

copyButton:SetScript("OnClick", function()
    NS.ShowCopyUrlDialog()
end)

--------------------------------------------------
-- Close ("X") button for the expired banner
--------------------------------------------------
local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
NS.closeButton = closeButton
closeButton:SetSize(20, 20)
closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 4)
closeButton:Hide()

closeButton:SetScript("OnClick", function()
    NS.missedQueue = false
    frame:Hide()
    if NS.copyButton then
        NS.copyButton:Hide()
    end
end)

--------------------------------------------------
-- UpdateDisplay
--------------------------------------------------
function NS.UpdateDisplay()
    local queues = NS.CollectQueues()

    -- No active queues
    if #queues == 0 then
        NS.hasQueues = false

        if NS.missedQueue then
            -- Show "Queue Expired" banner
            frame:Show()

            local lines = {
                "|cffff2020Queue Expired|r",
                "Never miss a Q",
                "with |cffff8000QPopCV|r",
            }

            NS.baseText = table.concat(lines, "\n")

            if frame:IsMouseOver() then
                text:SetText(NS.baseText .. "\n" .. (NS.HINT_TEXT or ""))
            else
                text:SetText(NS.baseText)
            end

            -- No queues -> no pause button
            if NS.pauseButton then
                NS.pauseButton:Hide()
            end

            -- Show Copy Url + close buttons
            if NS.copyButton then
                NS.copyButton:Show()
            end
            if NS.closeButton then
                NS.closeButton:Show()
            end

            Resize()
            return
        else
            -- Nothing to show
            NS.baseText = ""
            frame:Hide()
            if NS.pauseButton then NS.pauseButton:Hide() end
            if NS.copyButton then NS.copyButton:Hide() end
            if NS.closeButton then NS.closeButton:Hide() end
            return
        end
    end

    -- We have active queues; clear any expired state UI
    NS.hasQueues = true
    NS.missedQueue = false
    frame:Show()
    if NS.copyButton then NS.copyButton:Hide() end
    if NS.closeButton then NS.closeButton:Hide() end

    local lines = {}
    local anyUnpaused = false

    for i, q in ipairs(queues) do
        if not q.paused then
            anyUnpaused = true
        end

        -- Title
        table.insert(lines, "|cffffd100" .. (q.name or ("Queue " .. q.index)) .. "|r")

        -- MMR for this bracket, if we have a sample
        if NS.GetLastMMRForBracket and q.bracket then
            local _, pre, post, change = NS.GetLastMMRForBracket(q.bracket)
            if pre and post and change then

                local color = "|cffbbbbbb" -- neutral
                if change > 0 then
                    color = "|cff00ff00"   -- green
                elseif change < 0 then
                    color = "|cffff0000"   -- red
                end

                local grey = NS.COLOR_GREY or "|cff9d9d9d"

                local mmrLine = string.format(
                    "%sMMR: %d → %d|r %s(%+d)|r",
                    grey,
                    pre,
                    post,
                    color,
                    change
                )

                table.insert(lines, mmrLine)
            end
        end

        -- Times
        if q.paused then
            -- Already-colored "Paused"
            table.insert(lines, q.avgStr)
        else
            table.insert(lines, "Avg: " .. q.avgStr)
            table.insert(lines, "In Q: " .. q.timeStr)
        end

        if i < #queues then
            table.insert(lines, "")
        end
    end

    -- Pause button is only meaningful if at least one queue is not paused,
    -- and the user has it enabled in options.
    if NS.pauseButton then
        if NS.pauseButtonEnabled == false then
            NS.pauseButton:Hide()
        else
            if anyUnpaused then
                NS.pauseButton:Show()
            else
                NS.pauseButton:Hide()
            end
        end
    end

    NS.baseText = table.concat(lines, "\n")

    if frame:IsMouseOver() then
        text:SetText(NS.baseText .. "\n" .. (NS.HINT_TEXT or ""))
    else
        text:SetText(NS.baseText)
    end

    Resize()
end
