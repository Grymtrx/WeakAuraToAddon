local ADDON_NAME, NS = ...

local frame = NS.frame

-- Register events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
frame:RegisterEvent("PVP_MATCH_COMPLETE")

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
        -- Restore saved position if we have one (account-wide)
        if NS.global and NS.global.point then
            frame:ClearAllPoints()
            frame:SetPoint(
                NS.global.point,
                UIParent,
                NS.global.relativePoint or NS.global.point,
                NS.global.x or 0,
                NS.global.y or 0
            )
        end

        NS.UpdateDisplay()

    elseif event == "UPDATE_BATTLEFIELD_STATUS" then
        CheckMissedQueues()
        NS.UpdateDisplay()

    elseif event == "PVP_MATCH_COMPLETE" then
        -- Let the scoreboard API settle before sampling MMR
        C_Timer.After(1, function()
            if NS.TrackLatestMMR then
                NS.TrackLatestMMR()
            end
            NS.UpdateDisplay()
        end)
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
