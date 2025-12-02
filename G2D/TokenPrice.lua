local TOKEN_EVENT = "TOKEN_MARKET_PRICE_UPDATED"
local GOLD_PER_COPPER = 1 / 10000

G2D_CurrentTokenPriceGold = G2D_CurrentTokenPriceGold or nil

function G2D_GetTokenPriceGold()
    return G2D_CurrentTokenPriceGold
end

local function PrintWowTokenPrice()
    if not C_WowTokenPublic or not C_WowTokenPublic.GetCurrentMarketPrice then
        print("|cff00aaffG2D|r WoW Token API unavailable.")
        return
    end

    local priceInCopper = C_WowTokenPublic.GetCurrentMarketPrice()
    if not priceInCopper or priceInCopper <= 0 then
        print("|cff00aaffG2D|r WoW Token price not available yet.")
        return
    end

    local goldAmount = priceInCopper * GOLD_PER_COPPER
    G2D_CurrentTokenPriceGold = goldAmount
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
        if type(G2D_PrintBagStatus) == "function" then
            G2D_PrintBagStatus()
        end
    end
end)
