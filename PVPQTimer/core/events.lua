local ADDON_NAME, NS = ...

local frame = NS.frame

-- Register events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
frame:RegisterEvent("PVP_MATCH_COMPLETE")
frame:RegisterEvent("PLAYER_LOGOUT")

--------------------------------------------------
-- Missed-queue detection
--------------------------------------------------
-- We track the last known status for each battlefield slot and
-- treat a transition from "confirm" -> "none" as an expired / missed queue.
local queueStates = {}

local function CheckMissedQueues()
    local max = GetMaxBattlefieldID() or 0

    for i = 1, max do
        local status = GetBattlefieldStatus(i)
        local prev   = queueStates[i]

        if status ~= prev then
            if prev == "confirm" and status == "none" then
                -- Queue popped and then vanished without entering: assume missed.
                NS.missedQueue = true
            end
            queueStates[i] = status
        end
    end
end

--------------------------------------------------
-- Event handler
--------------------------------------------------
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
    PVPQTimerDB = PVPQTimerDB or {}
    PVPQTimerDB.global = PVPQTimerDB.global or {}

    NS.db     = PVPQTimerDB
    NS.global = PVPQTimerDB.global

    local g = PVPQTimerDB.global
    if g and g.x and g.y then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", g.x, g.y)
    else
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end

    --  re-apply saved font size on login
    if NS.ApplyFontSize then
        local fontSize = (g and g.fontSize) or NS.FONT_SIZE or 13
        NS.ApplyFontSize(fontSize)
    end

    -- Default to true if never set before
    if g.enableBackground == nil then
        g.enableBackground = true
    end

     -- Re-apply saved background state, defaulting to true if never set
    if NS.ApplyBackgroundEnabled then
        local enabled = g and g.enableBackground
        NS.ApplyBackgroundEnabled(enabled)   -- nil => treated as true inside
    end

    -- Re-apply pause button settings
    if NS.ApplyPauseButtonConfig then
        NS.ApplyPauseButtonConfig()
    end

    NS.UpdateDisplay()


    elseif event == "UPDATE_BATTLEFIELD_STATUS" then
        CheckMissedQueues()
        NS.UpdateDisplay()

    elseif event == "PVP_MATCH_COMPLETE" then
        C_Timer.After(1, function()
            if NS.TrackLatestMMR then
                NS.TrackLatestMMR()
            end
        end)

    elseif event == "PLAYER_LOGOUT" then
        PVPQTimerDB = PVPQTimerDB or {}
        PVPQTimerDB.global = PVPQTimerDB.global or {}

        local fX, fY = frame:GetCenter()
        local uX, uY = UIParent:GetCenter()
        if fX and fY and uX and uY then
            local x = fX - uX
            local y = fY - uY

            PVPQTimerDB.global.point         = "CENTER"
            PVPQTimerDB.global.relativePoint = "CENTER"
            PVPQTimerDB.global.x             = x
            PVPQTimerDB.global.y             = y
        end
    end
end)


--------------------------------------------------
-- Timed updates while we actually have queues
--------------------------------------------------
local elapsed = 0
frame:SetScript("OnUpdate", function(_, dt)
    if not NS.hasQueues then return end

    elapsed = elapsed + dt
    if elapsed >= 0.25 then
        elapsed = 0
        NS.UpdateDisplay()
    end
end)