local ADDON_NAME, NS = ...

function NS.CollectQueues()
    local queues = {}
    local max = GetMaxBattlefieldID() or 0

    for i = 1, max do
        -- 5th arg is the paused/suspended flag (you saw it flip true/false in your test)
        local status, mapName, _, _, isPaused = GetBattlefieldStatus(i)

        if status == "queued" then
            local paused = isPaused and true or false

            local avgStr
            local timeStr

            if paused then
                -- Blizzard red "Paused"
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
