local ADDON_NAME, NS = ...

function NS.CollectQueues()
    local queues = {}
    local max = GetMaxBattlefieldID() or 0

    for i = 1, max do
        local status, map = GetBattlefieldStatus(i)
        if status == "queued" then
            table.insert(queues, {
                index    = i,
                rawName  = map,
                name     = NS.PRETTY_NAMES[map] or map or ("Queue " .. i),
                bracket  = NS.BRACKET_BY_QUEUE_NAME[map],
                avgStr   = NS.FormatMillisVerbose(GetBattlefieldEstimatedWaitTime(i) or 0),
                timeStr  = NS.FormatMillisVerbose(GetBattlefieldTimeWaited(i) or 0),
            })
        end
    end

    return queues
end