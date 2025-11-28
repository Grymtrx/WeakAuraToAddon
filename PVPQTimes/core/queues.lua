local ADDON_NAME, NS = ...

--------------------------------------------------
-- Collect active PvP queues we care about
--------------------------------------------------
function NS.CollectQueues()
    local queues = {}
    local max = GetMaxBattlefieldID() or 0

    for i = 1, max do
        -- 5th return is "suspended" / paused (e.g. while in follower dungeon)
        local status, mapName, _, _, isSuspended = GetBattlefieldStatus(i)

        if status == "queued" and mapName then
            local paused = isSuspended and true or false
            local avgStr, timeStr

            if paused then
                -- Blizzard-red "Paused"
                avgStr  = "|cffff2020Paused|r"
                timeStr = "|cffff2020Paused|r"
            else
                avgStr  = NS.FormatMillisVerbose(GetBattlefieldEstimatedWaitTime(i) or 0)
                timeStr = NS.FormatMillisVerbose(GetBattlefieldTimeWaited(i) or 0)
            end

            table.insert(queues, {
                index    = i,
                rawName  = mapName,
                name     = NS.PRETTY_NAMES[mapName] or mapName or ("Queue " .. i),
                bracket  = NS.BRACKET_BY_QUEUE_NAME[mapName],
                paused   = paused,
                avgStr   = avgStr,
                timeStr  = timeStr,
            })
        end
    end

    return queues
end
