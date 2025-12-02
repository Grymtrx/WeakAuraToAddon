local TOKEN_EVENT = "TOKEN_MARKET_PRICE_UPDATED"

local function PrintWowTokenPrice()
    if not C_WowTokenPublic or not C_WowTokenPublic.GetCurrentMarketPrice then
        print("WoW Token API unavailable.")
        return
    end

    local priceInCopper = C_WowTokenPublic.GetCurrentMarketPrice()
    if not priceInCopper or priceInCopper <= 0 then
        print("WoW Token price not available yet.")
        return
    end

    local goldAmount = priceInCopper / 10000 -- convert copper to gold
    print(string.format("WoW Token price: %.0f gold", goldAmount))
end

local function RequestWowTokenPrice()
    if C_WowTokenPublic and C_WowTokenPublic.UpdateMarketPrice then
        C_WowTokenPublic.UpdateMarketPrice()
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent(TOKEN_EVENT)

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        RequestWowTokenPrice()
    elseif event == TOKEN_EVENT then
        PrintWowTokenPrice()
    end
end)
