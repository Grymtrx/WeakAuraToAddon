local addonName = ...

local function IsAddonLoadedCompat(name)
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded(name)
    elseif type(IsAddOnLoaded) == "function" then
        return IsAddOnLoaded(name)
    end
    return false
end

local toggleCB
local bracketCheckboxes = {}
local showSelections = {}
local showSelectedOnly = true
local db
local externalVisibility = {}

local bracketOrder = {
    { key = "RatedSoloShuffle", defaultShown = true },
    { key = "Arena2v2", defaultShown = true },
    { key = "Arena3v3", defaultShown = true },
    { key = "RatedBGBlitz", defaultShown = true },
    { key = "RatedBG", defaultShown = true },
}

local function InitializeSavedVariables()
    TogglePVPBracketsDB = TogglePVPBracketsDB or {}
    db = TogglePVPBracketsDB
    db.selections = db.selections or {}

    for _, info in ipairs(bracketOrder) do
        if db.selections[info.key] == nil then
            db.selections[info.key] = info.defaultShown
        else
            db.selections[info.key] = db.selections[info.key] and true or false
        end
    end

    if db.showSelectedOnly == nil then
        db.showSelectedOnly = true
    else
        db.showSelectedOnly = db.showSelectedOnly and true or false
    end

    showSelections = db.selections
    showSelectedOnly = db.showSelectedOnly
end

local function ShouldShowBracket(key)
    local override = externalVisibility[key]
    if override ~= nil then
        return override
    end
    if not showSelectedOnly then
        return true
    end
    return showSelections[key]
end

local function UpdateBracketLayout(frame)
    local previous

    for _, info in ipairs(bracketOrder) do
        local row = frame[info.key]
        if row then
            row:ClearAllPoints()
            if ShouldShowBracket(info.key) then
                row:Show()
                if previous then
                    row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
                else
                    row:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 15, -10)
                end
                previous = row
            else
                row:Hide()
            end
        end
    end
end

function TogglePVPBrackets_SetExternalVisibility(key, state)
    if not key then
        return
    end

    local previous = externalVisibility[key]
    if previous == state then
        return
    end

    externalVisibility[key] = state

    local frame = ConquestFrame
    if frame and frame._TogglePVPBracketsSetup then
        UpdateBracketLayout(frame)
    end
end

local function SetupBracketCheckboxes(frame)
    for _, info in ipairs(bracketOrder) do
        local row = frame[info.key]
        if row and not bracketCheckboxes[info.key] then
            if showSelections[info.key] == nil then
                showSelections[info.key] = info.defaultShown
            else
                showSelections[info.key] = showSelections[info.key] and true or false
            end

            local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            checkbox:SetSize(14, 14)
            checkbox:ClearAllPoints()
            checkbox:SetPoint("RIGHT", row, "LEFT", 3, 0)
            checkbox:SetChecked(showSelections[info.key])

            if checkbox.text then
                checkbox.text:SetText("")
            end
            if checkbox.Text then
                checkbox.Text:SetText("")
            end

            checkbox:SetScript("OnClick", function(self)
                showSelections[info.key] = self:GetChecked()
                UpdateBracketLayout(frame)
            end)

            checkbox:HookScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Toggle Visibility", nil, nil, nil, nil, true)
            end)

            checkbox:HookScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            bracketCheckboxes[info.key] = checkbox
        end
    end
end

local function Setup()
    local frame = ConquestFrame
    if not frame or frame._TogglePVPBracketsSetup then
        return
    end
    frame._TogglePVPBracketsSetup = true

    InitializeSavedVariables()
    SetupBracketCheckboxes(frame)

    toggleCB = CreateFrame("CheckButton", "TogglePVPBracketsToggle", frame, "UICheckButtonTemplate")
    toggleCB:SetSize(15, 15)

    toggleCB.text = toggleCB:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toggleCB.text:SetPoint("LEFT", toggleCB, "RIGHT", 4, 0)
    toggleCB.text:SetTextColor(1, 0.82, 0)
    toggleCB.text:SetText("Show Selected Only")

    toggleCB:SetScript("OnClick", function(self)
        showSelectedOnly = self:GetChecked()
        if db then
            db.showSelectedOnly = showSelectedOnly
        end
        UpdateBracketLayout(frame)
    end)

    if ConquestJoinButton then
        toggleCB:ClearAllPoints()
        toggleCB:SetPoint("RIGHT", ConquestJoinButton, "LEFT", -120, 0)
    end

    toggleCB:SetChecked(showSelectedOnly)
    UpdateBracketLayout(frame)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, arg1)
    if arg1 == "Blizzard_PVPUI" then
        Setup()
    elseif arg1 == addonName and IsAddonLoadedCompat("Blizzard_PVPUI") then
        Setup()
    end
end)
