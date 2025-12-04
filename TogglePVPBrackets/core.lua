local addonName = ...

local toggleCB
local bracketCheckboxes = {}
local hideSelections = {}
local hideSelectedEnabled = true

local bracketOrder = {
    { key = "RatedSoloShuffle", defaultHidden = false },
    { key = "Arena2v2", defaultHidden = false },
    { key = "Arena3v3", defaultHidden = false },
    { key = "RatedBGBlitz", defaultHidden = true },
    { key = "RatedBG", defaultHidden = true },
}

local function ShouldHideBracket(key)
    return hideSelectedEnabled and hideSelections[key]
end

local function UpdateBracketLayout(frame)
    local previous

    for _, info in ipairs(bracketOrder) do
        local row = frame[info.key]
        if row then
            row:ClearAllPoints()
            if ShouldHideBracket(info.key) then
                row:Hide()
            else
                row:Show()
                if previous then
                    row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, 0)
                else
                    row:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 15, -10)
                end
                previous = row
            end
        end
    end
end

local function SetupBracketCheckboxes(frame)
    for _, info in ipairs(bracketOrder) do
        local row = frame[info.key]
        if row and not bracketCheckboxes[info.key] then
            hideSelections[info.key] = hideSelections[info.key] or info.defaultHidden

            local checkbox = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
            checkbox:SetSize(14, 14)
            checkbox:ClearAllPoints()
            checkbox:SetPoint("RIGHT", row, "LEFT", 3, 0)
            checkbox:SetChecked(hideSelections[info.key])

            if checkbox.text then
                checkbox.text:SetText("")
            end
            if checkbox.Text then
                checkbox.Text:SetText("")
            end

            checkbox:SetScript("OnClick", function(self)
                hideSelections[info.key] = self:GetChecked()
                UpdateBracketLayout(frame)
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

    SetupBracketCheckboxes(frame)

    toggleCB = CreateFrame("CheckButton", "TogglePVPBracketsToggle", frame, "UICheckButtonTemplate")
    toggleCB:SetSize(15, 15)

    toggleCB.text = toggleCB:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toggleCB.text:SetPoint("LEFT", toggleCB, "RIGHT", 4, 0)
    toggleCB.text:SetTextColor(1, 0.82, 0)
    toggleCB.text:SetText("Hide Selected")

    toggleCB:SetScript("OnClick", function(self)
        hideSelectedEnabled = self:GetChecked()
        UpdateBracketLayout(frame)
    end)

    if ConquestJoinButton then
        toggleCB:ClearAllPoints()
        toggleCB:SetPoint("RIGHT", ConquestJoinButton, "LEFT", -120, 0)
    end

    toggleCB:SetChecked(true)
    UpdateBracketLayout(frame)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, _, arg1)
    if arg1 == "Blizzard_PVPUI" then
        Setup()
    elseif arg1 == addonName and IsAddOnLoaded("Blizzard_PVPUI") then
        Setup()
    end
end)
