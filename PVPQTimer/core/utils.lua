local ADDON_NAME, NS = ...

-- Time formatting utilities
function NS.FormatMillisVerbose(millis)
    if not millis or millis <= 0 then return "0 sec" end

    local sec = math.floor(millis / 1000 + 0.5)
    local h   = math.floor(sec / 3600)
    local m   = math.floor((sec % 3600) / 60)
    local s   = sec % 60

    local parts = {}
    if h > 0 then table.insert(parts, h .. " hr") end
    if m > 0 or h > 0 then table.insert(parts, m .. " min") end
    table.insert(parts, s .. " sec")

    return table.concat(parts, " ")
end