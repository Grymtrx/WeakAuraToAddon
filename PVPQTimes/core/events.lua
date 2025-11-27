local ADDON_NAME, NS = ...

local frame = NS.frame

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
frame:RegisterEvent("PVP_MATCH_COMPLETE")

frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if NS.db.point then
            frame:ClearAllPoints()
            frame:SetPoint(NS.db.point, UIParent, NS.db.relativePoint or NS.db.point, NS.db.x or 0, NS.db.y or 0)
        end
        NS.UpdateDisplay()

    elseif event == "UPDATE_BATTLEFIELD_STATUS" then
        NS.UpdateDisplay()

    elseif event == "PVP_MATCH_COMPLETE" then
        C_Timer.After(1, function()
            NS.TrackLatestMMR()
            NS.UpdateDisplay()
        end)
    end
end)

-- Update timed
local elapsed = 0
frame:SetScript("OnUpdate", function(_, dt)
    if not NS.hasQueues then return end
    elapsed = elapsed + dt
    if elapsed >= 0.25 then
        elapsed = 0
        NS.UpdateDisplay()
    end
end)