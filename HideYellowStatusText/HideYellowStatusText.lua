local DURATION = 1

local function FadeHide()
    local widget = UIWidgetTopCenterContainerFrame
    if not widget then
        return
    end

    if UIFrameFadeStop then
        UIFrameFadeStop(widget)
    end

    widget:Show()
    UIFrameFadeOut(widget, DURATION, widget:GetAlpha() or 1, 0)

    C_Timer.After(DURATION, function()
        if InCombatLockdown() then
            widget:Hide()
            widget:SetAlpha(1)
        end
    end)
end

local function FadeShow()
    local widget = UIWidgetTopCenterContainerFrame
    if not widget then
        return
    end

    if UIFrameFadeStop then
        UIFrameFadeStop(widget)
    end

    widget:SetAlpha(0)
    widget:Show()
    UIFrameFadeIn(widget, DURATION, 0, 1)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        FadeHide()
    elseif event == "PLAYER_REGEN_ENABLED" then
        FadeShow()
    elseif InCombatLockdown() then
        FadeHide()
    else
        FadeShow()
    end
end)
