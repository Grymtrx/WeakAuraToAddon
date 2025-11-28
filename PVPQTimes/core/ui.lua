local ADDON_NAME, NS = ...

--------------------------------------------------
-- QPopCV link popup
--------------------------------------------------
StaticPopupDialogs["PVPQTIMES_QPOPCV_LINK"] = {
    text = "QPopCV link:",
    button1 = OKAY,
    hasEditBox = true,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self)
        local eb = self.editBox
        eb:SetText(NS.QPOPCV_LINK or "")
        eb:SetFocus()
        eb:HighlightText()
    end,
    OnAccept = function(self) end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
}

function NS.ShowQPopCVLinkPopup()
    StaticPopup_Show("PVPQTIMES_QPOPCV_LINK")
end

--------------------------------------------------
-- Create Frame
--------------------------------------------------
local frame = CreateFrame("Frame", "PVPQTimesFrame", UIParent, "BackdropTemplate")
NS.frame = frame

frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
frame:Hide()

frame:SetBackdrop({
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true, tileSize = 16, edgeSize = 16,
    insets   = { left = 4, right = 4, top = 4, bottom = 4 },
})
frame:SetBackdropColor(0, 0, 0, 0.75)
frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

frame:SetClampedToScreen(true)
frame:SetFrameStrata("MEDIUM")
frame:SetFrameLevel(10)

--------------------------------------------------
-- Dragging / position save (account-wide)
--------------------------------------------------
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    NS.db.point, NS.db.relativePoint, NS.db.x, NS.db.y = p, rp, x, y
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
    text:SetFont(font, NS.FONT_SIZE or size, NS.FONT_FLAGS or flags)
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
    NS.ShowQPopCVLinkPopup()
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
            local label, pre, post, change = NS.GetLastMMRForBracket(q.bracket)
            if label and pre and post and change then
                local color = "|cffbbbbbb"
                if change > 0 then
                    color = "|cff00ff00"
                elseif change < 0 then
                    color = "|cffff0000"
                end

                local mmrLine = string.format(
                    "%s%s %d › %d %s(%+d)|r",
                    NS.COLOR_GREY or "|cff9d9d9d",
                    label,
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

    -- Pause button is only meaningful if at least one queue is not paused
    if NS.pauseButton then
        if anyUnpaused then
            NS.pauseButton:Show()
        else
            NS.pauseButton:Hide()
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