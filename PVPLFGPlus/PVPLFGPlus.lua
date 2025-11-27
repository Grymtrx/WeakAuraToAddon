local ADDON_NAME = ...

-- Localize globals
local C_LFGList                  = C_LFGList
local C_ChallengeMode            = C_ChallengeMode
local GetSearchResultInfo        = C_LFGList and C_LFGList.GetSearchResultInfo
local GetApplicantInfo           = C_LFGList and C_LFGList.GetApplicantInfo
local GetApplicantMemberInfo     = C_LFGList and C_LFGList.GetApplicantMemberInfo
local GetDungeonScoreRarityColor = C_ChallengeMode and C_ChallengeMode.GetDungeonScoreRarityColor
local hooksecurefunc             = hooksecurefunc

local allianceIcon = "Interface\\PVPFrame\\PVP-Currency-Alliance"
local hordeIcon    = "Interface\\PVPFrame\\PVP-Currency-Horde"

-- Crop faction icon a bit so it looks Blizzard-clean
local function FormatFactionIcon(iconPath)
    -- 16x16, using a 64x64 texture with inner crop (5–59) so it’s not chunky
    return ("|T%s:16:16:0:0:64:64:5:59:5:59|t"):format(iconPath)
end

-- Namespace table
local Addon = {}

------------------------------------------------
-- Helpers
------------------------------------------------

function Addon:GetFactionIcon(factionGroup)
    -- factionGroup: 0 = Horde, 1 = Alliance
    return (factionGroup == 1) and allianceIcon or hordeIcon
end

function Addon:GetLeaderBestRating(info)
    local list = info and info.leaderPvpRatingInfo
    if not list or #list == 0 then
        return 0
    end

    local best = 0
    for i = 1, #list do
        local rating = list[i].rating
        if rating and rating > best then
            best = rating
        end
    end
    return best
end

function Addon:FormatRatingColored(rating)
    rating = rating or 0
    if rating <= 0 then
        return "0"
    end

    -- 🔵 Custom Tier: 2700+ = Blizzard Blue
    if rating >= 2700 then
        -- Blizzard Blue: hex #00CCFF → |cff00ccff
        return ("|cff00ccff%d|r"):format(rating)
    end

    -- Default: Blizzard's M+ rating colors
    if GetDungeonScoreRarityColor then
        local color = GetDungeonScoreRarityColor(rating)
        if color then
            return color:WrapTextInColorCode(("%d"):format(rating))
        end
    end

    -- Fallback (shouldn’t really ever be used)
    return ("%d"):format(rating)
end


-- Soft cap comments so they don’t blow out the row
local COMMENT_MAX_LEN = 80

function Addon:ShortenComment(comment)
    if not comment or comment == "" then
        return ""
    end
    if #comment <= COMMENT_MAX_LEN then
        return comment
    end
    return comment:sub(1, COMMENT_MAX_LEN - 3) .. "..."
end

local DEAD_STATUSES = {
    timedout          = true,
    cancelled         = true,
    failed            = true,
    declined          = true,
    declined_full     = true,
    declined_delisted = true,
}

function Addon:IsDeadApplication(applicantInfo)
    if not applicantInfo then
        return false
    end
    local status  = applicantInfo.applicationStatus
    local pending = applicantInfo.pendingApplicationStatus
    return pending == "cancelled" or (status and DEAD_STATUSES[status])
end

-- Style listing fonts once per entry to look “addon polished”
function Addon:StyleEntryFonts(entry)
    if entry._PVPLFGPlusStyled then
        return
    end
    entry._PVPLFGPlusStyled = true

    if entry.Name then
        -- Keep its current size, just add OUTLINE
        local font, size = entry.Name:GetFont()
        entry.Name:SetFont(font, size, "OUTLINE")
    end

    if entry.ActivityName then
        -- Use GameFontHighlightSmall and outline for the grey line
        if GameFontHighlightSmall then
            entry.ActivityName:SetFontObject(GameFontHighlightSmall)
        end
        local font, size = entry.ActivityName:GetFont()
        entry.ActivityName:SetFont(font, size, "OUTLINE")
    end
end

-- Style applicant fonts once per row
function Addon:StyleApplicantFonts(member)
    if member._PVPLFGPlusStyled then
        return
    end
    member._PVPLFGPlusStyled = true

    if member.Name then
        local font, size = member.Name:GetFont()
        member.Name:SetFont(font, size, "OUTLINE")
    end
end

------------------------------------------------
-- Search entries (group listings)
------------------------------------------------

function Addon:UpdateSearchEntry(entry)
    if not entry or not entry.resultID then
        return
    end

    local frame = LFGListFrame
    if not frame or not frame.SearchPanel or not frame.SearchPanel:IsShown() then
        return
    end

    local info = GetSearchResultInfo(entry.resultID)
    if not info then
        return
    end

    -- Only touch listings that actually expose PvP rating info
    if not info.leaderPvpRatingInfo or #info.leaderPvpRatingInfo == 0 then
        return
    end

    -- Make fonts pretty once
    self:StyleEntryFonts(entry)

    -- [CR] Title (CR colored like M+ score)
    local bestRating = self:GetLeaderBestRating(info)
    local ratingText = self:FormatRatingColored(bestRating)

    if entry.Name then
        local title = entry.Name:GetText()
        if not title or title == "" then
            title = "Unnamed"
        end
        entry.Name:SetText(("[%s] %s"):format(ratingText, title))
    end

    -- Grey line: faction icon + shortened comment
    local factionIconPath = self:GetFactionIcon(info.leaderFactionGroup)
    local iconMarkup      = FormatFactionIcon(factionIconPath)
    local comment         = self:ShortenComment(info.comment or "")

    if entry.ActivityName then
        if comment ~= "" then
            entry.ActivityName:SetText(iconMarkup .. " " .. comment)
        else
            entry.ActivityName:SetText(iconMarkup)
        end
    end

    -- Keep Blizzard delisted tint behavior
    if info.isDelisted then
        local c = LFG_LIST_DELISTED_FONT_COLOR
        if entry.Name then
            entry.Name:SetTextColor(c.r, c.g, c.b)
        end
        if entry.ActivityName then
            entry.ActivityName:SetTextColor(c.r, c.g, c.b)
            entry.ActivityName:SetVertexColor(1, 1, 1, 0.4)
        end
    end
end

------------------------------------------------
-- Applicants (people applying to your group)
------------------------------------------------

function Addon:UpdateApplicantMemberRow(member, appID, memberIdx)
    if not member or not appID or not memberIdx or not member.Name then
        return
    end

    local applicantInfo = GetApplicantInfo(appID)
    if not applicantInfo then
        return
    end

    -- Style fonts once
    self:StyleApplicantFonts(member)

    local _, displayName, _, _, _, _, _, _, _, _, _, _, factionGroup =
        GetApplicantMemberInfo(appID, memberIdx)

    local factionIconPath = self:GetFactionIcon(factionGroup)
    local iconMarkup      = FormatFactionIcon(factionIconPath)
    local nameText        = displayName or member.Name:GetText() or "Unnamed"

    member.Name:SetText(("%s %s"):format(iconMarkup, nameText))

    if self:IsDeadApplication(applicantInfo) then
        member.Name:SetVertexColor(1, 1, 1, 0.4)
    else
        member.Name:SetVertexColor(1, 1, 1, 1)
    end
end

------------------------------------------------
-- Hook setup
------------------------------------------------

local hooksInstalled = false

local function InstallHooks()
    if hooksInstalled then
        return
    end
    hooksInstalled = true

    if type(LFGListSearchEntry_Update) == "function" then
        hooksecurefunc("LFGListSearchEntry_Update", function(entry, ...)
            Addon:UpdateSearchEntry(entry)
        end)
    end

    if type(LFGListApplicationViewer_UpdateApplicantMember) == "function" then
        hooksecurefunc("LFGListApplicationViewer_UpdateApplicantMember", function(member, appID, memberIdx, ...)
            Addon:UpdateApplicantMemberRow(member, appID, memberIdx)
        end)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == "Blizzard_LookingForGroup" or arg1 == ADDON_NAME then
            InstallHooks()
        end
    end
end)
