local addonName = ...

local toggleCB -- forward reference for positioning helper

local function ApplyFilter(frame)
    frame.RatedBG:Hide()
    frame.RatedBGBlitz:Hide()

    frame.RatedSoloShuffle:ClearAllPoints()
    frame.RatedSoloShuffle:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 15, -10)

    frame.Arena2v2:ClearAllPoints()
    frame.Arena2v2:SetPoint("TOPLEFT", frame.RatedSoloShuffle, "BOTTOMLEFT", 0, 0)

    frame.Arena3v3:ClearAllPoints()
    frame.Arena3v3:SetPoint("TOPLEFT", frame.Arena2v2, "BOTTOMLEFT", 0, 0)

    if toggleCB then
        toggleCB:ClearAllPoints()
        toggleCB:SetPoint("TOPLEFT", frame.Arena3v3, "BOTTOMLEFT", 2, -2)
    end
end

local function RemoveFilter(frame)
    frame.RatedBG:Show()
    frame.RatedBGBlitz:Show()

    frame.RatedSoloShuffle:ClearAllPoints()
    frame.RatedSoloShuffle:SetPoint("TOPLEFT", frame.Inset, "TOPLEFT", 15, -10)

    frame.Arena2v2:ClearAllPoints()
    frame.Arena2v2:SetPoint("TOPLEFT", frame.RatedSoloShuffle, "BOTTOMLEFT", 0, 0)

    frame.Arena3v3:ClearAllPoints()
    frame.Arena3v3:SetPoint("TOPLEFT", frame.Arena2v2, "BOTTOMLEFT", 0, 0)

    frame.RatedBGBlitz:ClearAllPoints()
    frame.RatedBGBlitz:SetPoint("TOPLEFT", frame.Arena3v3, "BOTTOMLEFT", 0, 0)

    frame.RatedBG:ClearAllPoints()
    frame.RatedBG:SetPoint("TOPLEFT", frame.RatedBGBlitz, "BOTTOMLEFT", 0, 0)

    if toggleCB then
        toggleCB:ClearAllPoints()
        toggleCB:SetPoint("TOPLEFT", frame.RatedBG, "BOTTOMLEFT", 2, -2)
    end
end

local function Setup()
    local frame = ConquestFrame
    if not frame or frame._TogglePVPBracketsSetup then
        return
    end
    frame._TogglePVPBracketsSetup = true

    toggleCB = CreateFrame("CheckButton", "TogglePVPBracketsToggle", frame, "UICheckButtonTemplate")
    toggleCB:SetSize(24, 24)

    toggleCB.text = toggleCB:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    toggleCB.text:SetPoint("LEFT", toggleCB, "RIGHT", 4, 0)
    toggleCB.text:SetText("Hide BGs")

    toggleCB:SetScript("OnClick", function(self)
        if self:GetChecked() then
            ApplyFilter(frame)
        else
            RemoveFilter(frame)
        end
    end)

    toggleCB:SetChecked(true)
    ApplyFilter(frame)
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
