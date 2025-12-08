local addonName, ns = ...

local BRACKETS = ns.BRACKETS
local GetStats = ns.GetStats

-- WoW color codes use |cffRRGGBB ... |r
local function GetWinrateColorCode(wr)
    if wr < 45 then
        return "|cffff0000"   -- Red
    elseif wr < 48 then
        return "|cff9d9d9d"   -- Gray
    elseif wr < 50 then
        return "|cffffffff"   -- White
    elseif wr < 55 then
        return "|cff1eff00"   -- Green
    elseif wr < 60 then
        return "|cff0070dd"   -- Blue
    elseif wr < 70 then
        return "|cffa335ee"   -- Purple
    elseif wr < 80 then
        return "|cffff8000"   -- Orange
    elseif wr < 90 then
        return "|cff00ccff"   -- Blizzard Blue
    else
        return "|cff00ccff"   -- Blizzard Blue
    end
end

-- Create frames + tooltip for each bracket
function ns.CreateBracketFrames()
    for _, b in ipairs(BRACKETS) do
        if not b.frame then
            local f = CreateFrame("Frame", "ArenaWinrateFrame_" .. b.key, UIParent)
            f:SetFrameStrata("DIALOG")
            -- Height fixed; width will be set dynamically from text
            f:SetSize(1, 10)
            f:Hide()

            local text = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            text:ClearAllPoints()
            -- Left-anchored so text grows to the right
            text:SetPoint("LEFT", f, "LEFT", 0, 2)
            text:SetJustifyH("LEFT")
            text:SetTextColor(0.584, 0.580, 0.580, 0.85)

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
function ns.ResolveAnchors()
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

function ns.UpdateBracket(b)
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

    local wins, losses, winrate = GetStats(b.id)
    if not wins then
        frame:Hide()
        return
    end

    -- Build colored winrate string
    local color = GetWinrateColorCode(winrate)
    local text = string.format("%d - %d  %s(%.1f%%)%s", wins, losses, color, winrate, "|r")

    frame.text:SetText(text)

    -- Dynamically resize hover hitbox to text width
    local w = frame.text:GetStringWidth() or 0
    frame:SetWidth(w + 4)

    frame:ClearAllPoints()
    frame:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -4)
    frame:Show()
end

function ns.UpdateAll()
    for _, b in ipairs(BRACKETS) do
        ns.UpdateBracket(b)
    end
end