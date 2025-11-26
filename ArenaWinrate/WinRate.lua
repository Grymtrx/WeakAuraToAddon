-- ArenaWinrate

-- Bracket definition helper
local function B(id, key, anchorPath)
    return { id = id, key = key, anchorPath = anchorPath }
end

local BRACKETS = {
    B(7,  "Solo",   "ConquestFrame.RatedSoloShuffle.CurrentRating"),
    B(1,  "2v2",    "ConquestFrame.Arena2v2.CurrentRating"),
    B(2,  "3v3",    "ConquestFrame.Arena3v3.CurrentRating"),
    B(10, "BGBlitz","ConquestFrame.RatedBGBlitz.CurrentRating"),
    B(3,  "BG",     "ConquestFrame.RatedBG.CurrentRating"),
}

-- Create frames + tooltip for each bracket
local function CreateBracketFrames()
    for _, b in ipairs(BRACKETS) do
        if not b.frame then
            local f = CreateFrame("Frame", "ArenaWinrateFrame_" .. b.key, UIParent)
            f:SetFrameStrata("DIALOG")
            f:SetSize(1, 10)  -- height fixed, width set from text
            f:Hide()

            local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:ClearAllPoints()
            text:SetPoint("LEFT", f, "LEFT", 0, 2)   -- left-aligned, grows right
            text:SetJustifyH("LEFT")
            text:SetTextColor(0.584, 0.580, 0.580, 0.75)

            local font, size = text:GetFont()
            text:SetFont(font, size, "OUTLINE")

            f.text = text
            b.frame = f

            f:SetScript("OnEnter", function(self)
                if not self:IsShown() then return end
                local t = self.text and self.text:GetText()
                if not t or t == "" then return end

                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Wins - Losses (Winrate%)", 0.9, 0.9, 0.9)
                GameTooltip:Show()
            end)

            f:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end
    end
end

-- Resolve and cache each bracket's CurrentRating fontstring
local function ResolveAnchors()
    for _, b in ipairs(BRACKETS) do
        if not b.anchor then
            local obj = _G
            for segment in string.gmatch(b.anchorPath, "[^%.]+") do
                obj = obj and obj[segment]
                if not obj then break end
            end
            b.anchor = obj
        end
    end
end

-- Returns "wins - losses (xx.x%)" or "" if no games played
local function GetStats(id)
    local total, wins

    if id == 7 then
        total = select(12, GetPersonalRatedInfo(id)) -- Solo Shuffle
        wins  = select(13, GetPersonalRatedInfo(id))
    else
        total = select(4, GetPersonalRatedInfo(id))  -- 2s / 3s / BG / BGBlitz
        wins  = select(5, GetPersonalRatedInfo(id))
    end

    if not total or total == 0 or not wins then
        return ""
    end

    local losses  = total - wins
    local winrate = (wins / total) * 100
    return string.format("%d - %d (%.1f%%)", wins, losses, winrate)
end

local function UpdateBracket(b)
    local frame = b.frame
    if not frame or not ConquestFrame or not ConquestFrame:IsShown() then
        if frame then frame:Hide() end
        return
    end

    local anchor = b.anchor
    if not anchor or not anchor:IsVisible() then
        frame:Hide()
        return
    end

    local wlr = GetStats(b.id)
    if wlr == "" then
        frame:Hide()
        return
    end

    frame.text:SetText(wlr)

    local w = frame.text:GetStringWidth() or 0
    frame:SetWidth(w + 4)

    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    frame:Show()
end

local function UpdateAll()
    for _, b in ipairs(BRACKETS) do
        UpdateBracket(b)
    end
end

-- Event driver
local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PVP_RATED_STATS_UPDATE")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")

driver:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_PVPUI" then
        CreateBracketFrames()
        ResolveAnchors()

        if ConquestFrame then
            ConquestFrame:HookScript("OnShow", function()
                ResolveAnchors()
                UpdateAll()
            end)

            ConquestFrame:HookScript("OnHide", function()
                for _, b in ipairs(BRACKETS) do
                    local f = b.frame
                    if f then f:Hide() end
                end
            end)
        end

    elseif (event == "PVP_RATED_STATS_UPDATE" or event == "PLAYER_ENTERING_WORLD")
        and ConquestFrame and ConquestFrame:IsShown()
    then
        UpdateAll()
    end
end)