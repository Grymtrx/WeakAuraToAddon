local addonName, ns = ...

local CreateBracketFrames = ns.CreateBracketFrames
local ResolveAnchors      = ns.ResolveAnchors
local UpdateAll           = ns.UpdateAll
local BRACKETS            = ns.BRACKETS

local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PVP_RATED_STATS_UPDATE")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Debounced update: collapse many events into one UpdateAll() call
local pendingUpdate = false

local function RequestUpdate()
    if pendingUpdate then return end
    pendingUpdate = true

    driver:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        pendingUpdate = false

        if ConquestFrame and ConquestFrame:IsShown() then
            UpdateAll()
        end
    end)
end

driver:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_PVPUI" then
        CreateBracketFrames()
        ResolveAnchors()

        if ConquestFrame then
            ConquestFrame:HookScript("OnShow", function()
                ResolveAnchors()
                RequestUpdate()
            end)

            ConquestFrame:HookScript("OnHide", function()
                for _, b in ipairs(BRACKETS) do
                    local f = b.frame
                    if f then f:Hide() end
                end
            end)
        end

    elseif event == "PVP_RATED_STATS_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        -- Only bother updating if the PvP panel is actually up
        if ConquestFrame and ConquestFrame:IsShown() then
            RequestUpdate()
        end
    end
end)