-- ArenaWinrate – Solo / 2v2 / 3v3 / Rated BG Blitz / Rated BG

local function ResolvePath(path)
    -- Turns "ConquestFrame.RatedSoloShuffle.CurrentRating" into the actual object
    local obj = _G
    for segment in string.gmatch(path, "[^%.]+") do
        obj = obj and obj[segment]
        if not obj then return nil end
    end
    return obj
end

local brackets = {
    {
        id = 7,
        key = "Solo",
        anchorPath = "ConquestFrame.RatedSoloShuffle.CurrentRating",
    },
    {
        id = 1,
        key = "Two",
        anchorPath = "ConquestFrame.Arena2v2.CurrentRating",
    },
    {
        id = 2,
        key = "Three",
        anchorPath = "ConquestFrame.Arena3v3.CurrentRating",
    },
    {
        id = 10, -- Rated BG Blitz
        key = "BGBlitz",
        anchorPath = "ConquestFrame.RatedBGBlitz.CurrentRating",
    },
    {
        id = 3,  -- Rated Battlegrounds (10v10)
        key = "BG",
        anchorPath = "ConquestFrame.RatedBG.CurrentRating",
    },
}

-- Create one small frame per bracket
for _, b in ipairs(brackets) do
    local f = CreateFrame("Frame", "ArenaWinrateFrame_" .. b.key, UIParent)
    f:SetFrameStrata("DIALOG")
    f:SetSize(140, 20)
    f:Hide()

    local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:ClearAllPoints()
    -- Left-anchored so the text only grows to the right
    text:SetPoint("LEFT", f, "LEFT", 0, 9)
    text:SetJustifyH("LEFT")
    text:SetTextColor(0.584, 0.580, 0.580, 0.75) -- #959494 @ ~75% alpha

    do
        local font, size, flags = text:GetFont()
        text:SetFont(font, size, "OUTLINE")
    end

    f.text = text
    b.frame = f
end

-- Returns "wins - losses (xx.x%)" or "" if bracket has no games
local function GetStats(id)
    local total, wins

    if id == 7 then
        -- Solo Shuffle
        total = select(12, GetPersonalRatedInfo(id))
        wins  = select(13, GetPersonalRatedInfo(id))
    else
        -- 2v2 / 3v3 / BG / BGBlitz
        total = select(4, GetPersonalRatedInfo(id))
        wins  = select(5, GetPersonalRatedInfo(id))
    end

    if not total or total == 0 or not wins then
        return ""
    end

    local losses  = total - wins
    local winrate = (wins / total) * 100
    return string.format("%d - %d (%.1f%%)", wins, losses, winrate)
end

-- Check if the specific bracket row (its parent) is actually visible
local function IsBracketRowVisible(b)
    if not ConquestFrame or not ConquestFrame:IsShown() then
        return false
    end

    local anchor = ResolvePath(b.anchorPath)
    if not anchor then
        return false
    end

    -- Most of those paths point to a FontString; use its parent row
    local row = anchor:GetParent()
    if row and row.IsVisible and row:IsVisible() then
        return true
    end

    return false
end

local function PositionBracket(b)
    if not b.frame then return end

    b.frame:ClearAllPoints()

    local anchor = ResolvePath(b.anchorPath)
    if anchor then
        -- Lock LEFT edges so there’s no horizontal drift between brackets
        b.frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    else
        -- No anchor: hide this bracket’s frame
        b.frame:Hide()
    end
end

local function UpdateBracket(b)
    if not b.frame then return end

    -- Require the bracket row to be visible
    if not IsBracketRowVisible(b) then
        b.frame:Hide()
        return
    end

    local wlr = GetStats(b.id)
    if wlr == "" then
        b.frame:Hide()
        return
    end

    b.frame.text:SetText(wlr)
    PositionBracket(b)
    b.frame:Show()
end

local function PositionAll()
    for _, b in ipairs(brackets) do
        PositionBracket(b)
    end
end

local function UpdateAll()
    for _, b in ipairs(brackets) do
        UpdateBracket(b)
    end
end

-- Driver frame
local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PVP_RATED_STATS_UPDATE")
driver:RegisterEvent("PLAYER_ENTERING_WORLD")

driver:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_PVPUI" then
        if ConquestFrame then
            ConquestFrame:HookScript("OnShow", function()
                PositionAll()
                UpdateAll()
            end)

            ConquestFrame:HookScript("OnHide", function()
                for _, b in ipairs(brackets) do
                    if b.frame then
                        b.frame:Hide()
                    end
                end
            end)
        end

    elseif event == "PVP_RATED_STATS_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
        if ConquestFrame and ConquestFrame:IsShown() then
            UpdateAll()
        end
    end
end)

-- Slash command: /aw to force reposition + update while PvP window is open
SLASH_AW1 = "/aw"
SlashCmdList.AW = function()
    PositionAll()
    UpdateAll()
end
