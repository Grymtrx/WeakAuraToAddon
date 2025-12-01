local addonName, ns = ...

local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_LOGIN")

driver:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            ns.InitDatabase()
        elseif arg1 == "Blizzard_PVPUI" then
            ns.AttachToConquestFrame()
        end
    elseif event == "PLAYER_LOGIN" then
        ns.AttachToConquestFrame()
    end
end)
