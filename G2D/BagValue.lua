local USD_PER_TOKEN = 20
local GOLD_PER_COPPER = 1 / 10000
local PREFIX = "|cff00aaffG2D|r"
local lastCopperPrinted = nil
local lastTokenPrinted = nil

local function GetLatestTokenPrice()
    if type(G2D_GetTokenPriceGold) == "function" then
        return G2D_GetTokenPriceGold()
    end
end

local function FormatGold(copper)
    return GetMoneyString(copper, true) or string.format("%.0f gold", copper * GOLD_PER_COPPER)
end

function G2D_PrintBagStatus()
    local copper = GetMoney()
    if type(copper) ~= "number" then
        print(PREFIX .. " Unable to read bag gold.")
        return
    end

    local tokenPrice = GetLatestTokenPrice()
    if lastCopperPrinted == copper and lastTokenPrinted == tokenPrice then
        return
    end

    local bagGold = copper * GOLD_PER_COPPER
    local bagUSD = tokenPrice and tokenPrice > 0 and (bagGold / tokenPrice) * USD_PER_TOKEN or nil

    local tokenText = tokenPrice and string.format("%.0f gold", tokenPrice) or "pending"
    local usdText = bagUSD and string.format("$%.2f", bagUSD) or "pending"

    print(string.format(
        "%s Bags: %s | Token: %s | USD: %s",
        PREFIX,
        FormatGold(copper),
        tokenText,
        usdText
    ))

    lastCopperPrinted = copper
    lastTokenPrinted = tokenPrice
end

SLASH_G2D1 = "/g2d"
SlashCmdList.G2D = G2D_PrintBagStatus

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_MONEY")

frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        C_Timer.After(1, G2D_PrintBagStatus)
    elseif event == "PLAYER_MONEY" then
        G2D_PrintBagStatus()
    end
end)
