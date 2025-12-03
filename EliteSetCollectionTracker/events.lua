local addonName, ns = ...

local InitDatabase            = ns.InitDatabase
local RefreshPlayerClass      = ns.RefreshPlayerClass
local UpdateSets              = ns.UpdateSets
local UpdateDisplay           = ns.UpdateDisplay
local TryAttachToConquestFrame = ns.TryAttachToConquestFrame

local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_LOGIN")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")
driver:RegisterEvent("TRANSMOG_COLLECTION_SOURCE_ADDED")
driver:RegisterEvent("PVP_RATED_STATS_UPDATE")

local function IsBlizzardPVPLoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded("Blizzard_PVPUI")
    elseif IsAddOnLoaded then
        return IsAddOnLoaded("Blizzard_PVPUI")
    end
end

local function RefreshCollections()
    if UpdateSets() then
        UpdateDisplay()
    end
end

driver:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            InitDatabase()
            RefreshPlayerClass()
            RefreshCollections()

            if IsBlizzardPVPLoaded() then
                TryAttachToConquestFrame()
            end
        elseif arg1 == "Blizzard_PVPUI" then
            TryAttachToConquestFrame()
        end

    elseif event == "PLAYER_LOGIN" then
        RefreshPlayerClass()
        RefreshCollections()

        if IsBlizzardPVPLoaded() then
            TryAttachToConquestFrame()
        end

    elseif event == "PLAYER_ENTERING_WORLD" or event == "TRANSMOG_COLLECTION_SOURCE_ADDED" or event == "PVP_RATED_STATS_UPDATE" then
        RefreshCollections()
    end
end)
