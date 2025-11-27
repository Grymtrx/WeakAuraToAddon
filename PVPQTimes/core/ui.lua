local ADDON_NAME, NS = ...

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
    insets   = { left=4, right=4, top=4, bottom=4 }
})
frame:SetBackdropColor(0,0,0,0.9)
frame:SetBackdropBorderColor(0.15,0.15,0.15,1)

--------------------------------------------------
-- Movable + saved position
--------------------------------------------------
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p,_,rp,x,y = self:GetPoint()
    NS.db.point, NS.db.relativePoint, NS.db.x, NS.db.y = p, rp, x, y
end)

--------------------------------------------------
-- Text
--------------------------------------------------
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
NS.text = text
text:SetJustifyH("LEFT")
text:SetPoint("CENTER")

local f = text:GetFont()
text:SetFont(f, NS.FONT_SIZE, NS.FONT_FLAGS)

--------------------------------------------------
-- Heartbeat Animation
--------------------------------------------------

local function CreateHeartbeatAnimation(parent)
    local group = parent:CreateAnimationGroup()
    group:SetLooping("REPEAT")

    -- Fade from 100% -> 60%
    local fadeOut = group:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1.0)
    fadeOut:SetToAlpha(0.6)
    fadeOut:SetDuration(0.4)
    fadeOut:SetOrder(1)

    -- Fade from 60% -> 100%
    local fadeIn = group:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.6)
    fadeIn:SetToAlpha(1.0)
    fadeIn:SetDuration(0.4)
    fadeIn:SetOrder(2)

    -- Hold at 100% to complete ~2s cycle
    local pause = group:CreateAnimation("Alpha")
    pause:SetFromAlpha(1.0)
    pause:SetToAlpha(1.0)
    pause:SetDuration(1.2)
    pause:SetOrder(3)

    return group
end

local heartbeatGroup = CreateHeartbeatAnimation(frame)

-- Only run the animation while visible
local Frame_Show = frame.Show
function frame:Show()
    Frame_Show(self)

    if not heartbeatGroup:IsPlaying() then
        heartbeatGroup:Play()
    end
end

local Frame_Hide = frame.Hide
function frame:Hide()
    Frame_Hide(self)

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
    frame:SetSize(w + NS.PADDING_X, h + NS.PADDING_Y)
end
NS.Resize = Resize

--------------------------------------------------
-- Hover hint
--------------------------------------------------
frame:SetScript("OnEnter", function()
    if NS.baseText ~= "" then
        text:SetText(NS.baseText .. "\n" .. NS.HINT_TEXT)
        Resize()
    end
end)

frame:SetScript("OnLeave", function()
    if NS.baseText ~= "" then
        text:SetText(NS.baseText)
        Resize()
    end
end)

--------------------------------------------------
-- Build display
--------------------------------------------------
function NS.UpdateDisplay()
    local queues = NS.CollectQueues()
    if #queues == 0 then
        NS.hasQueues = false
        NS.baseText = ""
        frame:Hide()
        return
    end

    NS.hasQueues = true
    frame:Show()

    local lines = {}

    for i, q in ipairs(queues) do
        -- Title
        table.insert(lines, "|cffffd100" .. q.name .. "|r")

        -- MMR
        local label, pre, post, change = NS.GetLastMMRForBracket(q.bracket)
        if label then
            local color = change>0 and "|cff00ff00" or change<0 and "|cffff0000" or "|cffbbbbbb"
            local mmrLine = string.format(
                "%s%s: %d › %d|r %s(%+d)|r",
                NS.COLOR_GREY, label, pre, post, color, change
            )
            table.insert(lines, mmrLine)
        end

        -- Times
        table.insert(lines, "Avg: " .. q.avgStr)
        table.insert(lines, "In Q: " .. q.timeStr)

        if i < #queues then
            table.insert(lines, "")
        end
    end

    NS.baseText = table.concat(lines, "\n")

    if frame:IsMouseOver() then
        text:SetText(NS.baseText .. "\n" .. NS.HINT_TEXT)
    else
        text:SetText(NS.baseText)
    end

    Resize()
end
