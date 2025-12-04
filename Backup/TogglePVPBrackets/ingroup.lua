local addonName = ...

local function UpdateSoloShuffleVisibility()
    if type(TogglePVPBrackets_SetExternalVisibility) == "function" then
        if IsInGroup() then
            TogglePVPBrackets_SetExternalVisibility("RatedSoloShuffle", false)
        else
            TogglePVPBrackets_SetExternalVisibility("RatedSoloShuffle", nil)
        end
        return
    end

    local frame = ConquestFrame
    if frame and frame.RatedSoloShuffle then
        frame.RatedSoloShuffle:SetShown(not IsInGroup())
    end
end

local function OnAddonLoaded(arg1)
    if arg1 == "Blizzard_PVPUI" then
        UpdateSoloShuffleVisibility()
    elseif arg1 == addonName and IsAddOnLoaded("Blizzard_PVPUI") then
        UpdateSoloShuffleVisibility()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        OnAddonLoaded(arg1)
    else
        UpdateSoloShuffleVisibility()
    end
end)
