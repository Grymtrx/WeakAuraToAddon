local addonName, ns = ...

local CLASS_ORDER = ns.CLASS_ORDER
local ICONS = ns.ICONS
local TOTAL_CLASSES = #CLASS_ORDER
local SECTION_GAP = 3

local ICON_SIZE = 19
local ICON_SPACING = 1
local ICONS_PER_ROW = 15

local frame
local hooked = false

local function GetClassName(token)
    local male = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]
    local female = LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[token]
    return male or female or token
end

local function LayoutIcons(order, gapBefore, gapSections)
    if not frame or not frame.label then
        return
    end

    -- Layout respects the frame's bottom-right anchor so the block grows left/up
    local total = #order
    local columns = math.min(total, ICONS_PER_ROW)
    local rows = math.ceil(total / ICONS_PER_ROW)
    local height = 24 + frame.label:GetStringHeight() + rows * ICON_SIZE + (rows - 1) * ICON_SPACING
    local additionalGap = math.max((gapSections or 0), 0) * SECTION_GAP
    local width = 16 + columns * ICON_SIZE + (columns - 1) * ICON_SPACING + additionalGap
    frame:SetSize(width, height)

    for idx, classToken in ipairs(order) do
        local icon = frame.iconByClass and frame.iconByClass[classToken]
        if icon then
            icon:ClearAllPoints()
            local row = math.floor((idx - 1) / ICONS_PER_ROW)
            local col = (idx - 1) % ICONS_PER_ROW
            local gapMultiplier = (gapBefore and gapBefore[idx]) or 0
            local gapOffset = gapMultiplier * SECTION_GAP
            -- Each icon anchors to the frame's top-right edge and flows leftward
            icon:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8 - col * (ICON_SIZE + ICON_SPACING) - gapOffset, -24 - row * (ICON_SIZE + ICON_SPACING))
        end
    end
end

local function EnsureFrame()
    if frame or not ConquestFrame then
        return frame
    end

    frame = CreateFrame("Frame", "EliteSetCollectionTrackerFrame", ConquestFrame)
    frame:SetFrameStrata("DIALOG")
    -- Root frame anchors to the ConquestFrame's bottom-right corner
    frame:SetPoint("TOPRIGHT", ConquestFrame, "TOPRIGHT", -2, -40)
    frame:Hide()

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetColorTexture(0, 0, 0, 0)
    bg:SetAllPoints()
    frame.bg = bg

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    -- Label anchors to the frame's top-right so text aligns with the icons
    label:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -9, -9)
    label:SetJustifyH("RIGHT")
    label:SetTextColor(1, 0.82, 0)
    label:SetText("(0/" .. TOTAL_CLASSES .. ") Elite Sets Collected")
    frame.label = label

    frame.icons = {}
    frame.iconByClass = {}

    for _, classToken in ipairs(CLASS_ORDER) do
        local icon = CreateFrame("Button", nil, frame)
        icon:SetSize(ICON_SIZE, ICON_SIZE)
        icon.class = classToken
        icon.prettyName = GetClassName(classToken)

        local tex = icon:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture(ICONS[classToken])
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon.texture = tex

        icon:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local classColor = RAID_CLASS_COLORS and RAID_CLASS_COLORS[self.class]
            if classColor then
                GameTooltip:AddLine(self.prettyName, classColor.r, classColor.g, classColor.b)
            else
                GameTooltip:AddLine(self.prettyName, 1, 1, 1)
            end

            local collected = ns.GetCollectedSets()
            local state = collected and collected[self.class]
            if state == nil then
                GameTooltip:AddLine("Log onto this class to register Elite appearance status.", 1, 0.82, 0)
            elseif state then
                GameTooltip:AddLine("Elite appearance collected", 0.2, 1, 0.2)
            else
                GameTooltip:AddLine("Elite appearance not collected", 1, 0.25, 0.25)
            end

            GameTooltip:Show()
        end)

        icon:SetScript("OnLeave", GameTooltip_Hide)

        frame.icons[#frame.icons + 1] = icon
        frame.iconByClass[classToken] = icon
    end

    LayoutIcons(CLASS_ORDER)

    return frame
end

function ns.UpdateDisplay()
    if not frame or not frame:IsShown() then
        return
    end

    local collected = ns.GetCollectedSets()
    local collectedOrder = {}
    local missingOrder = {}
    local unknownOrder = {}
    local gapBefore = {}

    local collectedCount = 0
    for _, icon in ipairs(frame.icons) do
        local hasSet = collected and collected[icon.class]
        if hasSet == nil then
            icon.texture:SetAlpha(0.25)
            icon.texture:SetDesaturated(true)
            icon.texture:SetVertexColor(1, 1, 1)
            unknownOrder[#unknownOrder + 1] = icon.class
        elseif hasSet then
            icon.texture:SetAlpha(1)
            icon.texture:SetDesaturated(false)
            icon.texture:SetVertexColor(1, 1, 1)
            collectedCount = collectedCount + 1
            collectedOrder[#collectedOrder + 1] = icon.class
        else
            icon.texture:SetAlpha(0.4)
            icon.texture:SetDesaturated(false)
            icon.texture:SetVertexColor(0.8, 0.2, 0.2)
            missingOrder[#missingOrder + 1] = icon.class
        end
    end

    local sorted = {}
    local gapCount = 0
    local function appendSection(section)
        if #section == 0 then
            return
        end
        for _, classToken in ipairs(section) do
            sorted[#sorted + 1] = classToken
            gapBefore[#sorted] = gapCount
        end
        gapCount = gapCount + 1
    end

    appendSection(collectedOrder)
    appendSection(missingOrder)
    appendSection(unknownOrder)

    LayoutIcons(sorted, gapBefore, math.max(gapCount - 1, 0))

    if frame.label then
        frame.label:SetText(string.format("(%d/%d) Elite Sets Collected", collectedCount, TOTAL_CLASSES))
    end
end

function ns.TryAttachToConquestFrame()
    if not ConquestFrame then
        return
    end

    local f = EnsureFrame()
    if not f then
        return
    end

    if not hooked then
        hooked = true

        ConquestFrame:HookScript("OnShow", function()
            if not frame then
                return
            end
            frame:Show()
            ns.UpdateDisplay()
        end)

        ConquestFrame:HookScript("OnHide", function()
            if frame then
                frame:Hide()
            end
        end)
    end

    if ConquestFrame:IsShown() then
        frame:Show()
        ns.UpdateDisplay()
    else
        frame:Hide()
    end
end
