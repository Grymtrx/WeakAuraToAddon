local addonName, ns = ...

local frame
local updateThrottle = 0

local CONFIRMED_COLOR = { 0.0, 0.45, 0.1 }
local PROJECTED_COLOR = { 0.75, 0.55, 0.0 }

local function FormatDuration(seconds)
    if seconds <= 0 then
        return "0"
    end
    return tostring(math.floor(seconds / 86400 + 0.5))
end

local function EnsureFrame()
    if frame then
        return frame
    end

    frame = CreateFrame("Frame", "SeasonProgressFrame", UIParent)
    frame:SetSize(220, 55)
    frame:SetPoint("TOP", UIParent, "TOP", 0, -80)
    frame:Hide()
    frame:SetFrameStrata("DIALOG")

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    title:SetPoint("TOP", frame, "TOP", 0, -4)
    title:SetText("Season Progress")
    title:SetTextColor(1, 0.82, 0)
    frame.title = title

    local bar = CreateFrame("StatusBar", nil, frame)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    -- Bar dimensions (width x height): adjust here for different footprint
    bar:SetSize(160, 5)
    bar:SetPoint("TOP", title, "BOTTOM", 0, -10)
    bar:SetMinMaxValues(0, 1)
    bar:SetStatusBarColor(CONFIRMED_COLOR[1], CONFIRMED_COLOR[2], CONFIRMED_COLOR[3])
    frame.bar = bar

    local bg = bar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.3, 0.0, 0.0, 0.8)
    frame.barBG = bg

    local border = frame:CreateTexture(nil, "ARTWORK")
    border:SetPoint("TOPLEFT", bar, -1, 1)
    border:SetPoint("BOTTOMRIGHT", bar, 1, -1)
    border:SetColorTexture(0, 0, 0, 1)
    frame.barBorder = border

    bar:EnableMouse(true)
    bar:SetScript("OnEnter", function()
        local startTimestamp, endTimestamp = ns.GetSeasonWindow()
        if not startTimestamp or not endTimestamp then
            return
        end
        local projected = ns.IsSeasonProjected()
        GameTooltip:SetOwner(bar, "ANCHOR_TOP")
        GameTooltip:AddLine("Season Window", 1, 0.82, 0)
        GameTooltip:AddLine(date("%m-%d-%Y", startTimestamp) .. " -> " .. date("%m-%d-%Y", endTimestamp), 1, 1, 1)
        GameTooltip:AddLine(projected and "Projected" or "Confirmed", projected and 1 or 0.75, projected and 0.82 or 1, projected and 0 or 0.75)
        GameTooltip:Show()
    end)
    bar:SetScript("OnLeave", GameTooltip_Hide)
    frame:SetScript("OnUpdate", function(_, elapsed)
        updateThrottle = updateThrottle + elapsed
        if updateThrottle >= 1 then
            updateThrottle = 0
            ns.UpdateSeasonVisuals()
        end
    end)

    return frame
end

function ns.UpdateSeasonVisuals()
    if not frame then
        return
    end

    local startTimestamp, endTimestamp = ns.GetSeasonWindow()
    local label = ns.GetSeasonLabel()
    local projected = ns.IsSeasonProjected()
    if label and label ~= "" then
        frame.title:SetText(string.format("%s Season", label))
    else
        frame.title:SetText("Season Progress")
    end

    if not startTimestamp or not endTimestamp or endTimestamp <= startTimestamp then
        frame.bar:SetValue(0)
        return
    end

    local now = time()
    local duration = endTimestamp - startTimestamp
    local elapsed = now - startTimestamp
    local percent = math.min(math.max(elapsed / duration, 0), 1)

    frame.bar:SetValue(percent)

    local color = projected and PROJECTED_COLOR or CONFIRMED_COLOR
    frame.bar:SetStatusBarColor(color[1], color[2], color[3])

    -- no text updates; hover tooltip conveys exact dates
end

function ns.AttachToConquestFrame()
    local f = EnsureFrame()
    if not f or not ConquestJoinButton then
        return
    end

    if not f._hooked and ConquestFrame then
        ConquestFrame:HookScript("OnShow", function()
            ns.AttachToConquestFrame()
            f:Show()
            ns.UpdateSeasonVisuals()
        end)
        ConquestFrame:HookScript("OnHide", function()
            if SeasonProgressFrame then
                SeasonProgressFrame:Hide()
            end
        end)
        f._hooked = true
    end

    f:ClearAllPoints()
    -- Anchor whole widget 300px to the right of the Conquest Join button
    f:SetPoint("CENTER", ConquestJoinButton, "CENTER", 278, 0)

    if ConquestFrame and ConquestFrame:IsShown() then
        f:Show()
        ns.UpdateSeasonVisuals()
    else
        f:Hide()
    end
end
