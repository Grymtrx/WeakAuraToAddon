local ADDON_NAME, NS = ...

local options = {
    enableBackground  = true,
    enableMMR         = true,
    enablePauseButton = true,
    pauseLocation     = "RIGHT",  -- or "LEFT"
    fontSize          = 12,
}

local pauseLocationList = {
    { value = "RIGHT", text = "RIGHT" },
    { value = "LEFT",  text = "LEFT"  },
}

--------------------------------------------------
-- Helpers
--------------------------------------------------

local function CreateTitle(parent, text, yOffset)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    fs:SetPoint("TOPLEFT", 16, yOffset)
    fs:SetText(text)
    return fs
end

local function CreateCheckbox(parent, label, tooltip, yOffset)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 16, yOffset)
    cb.Text:SetText(label)

    if tooltip then
        cb.tooltipText = label
        cb.tooltipRequirement = tooltip
    end

    return cb
end

local function CreateDropdown(parent, labelText, width, yOffset)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 16, yOffset)
    label:SetText(labelText)

    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -15, -2)
    dropdown:SetWidth(width or 150)

    return dropdown
end

local function CreateSlider(parent, label, minVal, maxVal, step, yOffset)
    local parentName = parent:GetName()
    local sliderName
    if parentName then
        sliderName = parentName .. label:gsub("%s+", "") .. "Slider"
    end

    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 16, yOffset)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    if slider.Text then
        slider.Text:SetText(label)
    end
    if slider.Low then
        slider.Low:SetText(tostring(minVal))
    end
    if slider.High then
        slider.High:SetText(tostring(maxVal))
    end

    return slider
end

--------------------------------------------------
-- Category Frame
--------------------------------------------------

local panel = CreateFrame("Frame", "PVPQTimerOptionsPanel", UIParent)
panel.name = "PVPQTimer"

local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(category)

--------------------------------------------------
-- Build UI once on first show
--------------------------------------------------

local built = false

local function BuildUI()
    if built then return end
    built = true

    -- Pull current settings from SavedVariables, if available
    if NS and NS.global then
        if NS.global.enableBackground ~= nil then
            options.enableBackground = NS.global.enableBackground
        end
        if NS.global.enableMMR ~= nil then
            options.enableMMR = NS.global.enableMMR
        end
        if NS.global.fontSize then
            options.fontSize = NS.global.fontSize
        end
        if NS.global.enablePauseButton ~= nil then
            options.enablePauseButton = NS.global.enablePauseButton
        end
        if NS.global.pauseLocation then
            options.pauseLocation = NS.global.pauseLocation
        end
    end

    --------------------------------------------------
    -- Title
    --------------------------------------------------
    CreateTitle(panel, "PVPQTimer Settings", -16)

    --------------------------------------------------
    -- Checkbox: Show Background & Border
    --------------------------------------------------
    local cbBG = CreateCheckbox(
        panel,
        "Show Background & Border",
        "Toggle a backdrop + border for the timer.",
        -56
    )
    cbBG:SetChecked(options.enableBackground)

    cbBG:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        options.enableBackground = checked

        if NS and NS.ApplyBackgroundEnabled then
            NS.ApplyBackgroundEnabled(checked)
        end
    end)

    --------------------------------------------------
    -- Checkbox: Show MMR
    --------------------------------------------------
    local cbMMR = CreateCheckbox(
        panel,
        "Show MMR",
        "When enabled, PVPQTimer will include MMR-related info in its display.",
        -86
    )
    cbMMR:SetChecked(options.enableMMR)

    cbMMR:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        options.enableMMR = checked

        -- Ensure SavedVariables exist and keep NS in sync
        PVPQTimerDB = PVPQTimerDB or {}
        PVPQTimerDB.global = PVPQTimerDB.global or {}

        NS.db     = PVPQTimerDB
        NS.global = PVPQTimerDB.global

        -- Persist the setting
        NS.global.enableMMR = checked

        -- Immediately refresh the display
        if NS.UpdateDisplay then
            NS.UpdateDisplay()
        end
    end)

    --------------------------------------------------
    -- Checkbox: Show Pause Button
    --------------------------------------------------
    local cbPause = CreateCheckbox(
        panel,
        "Show Pause Button",
        "Show a pause button next to the timer frame.",
        -116
    )
    cbPause:SetChecked(options.enablePauseButton)

    cbPause:SetScript("OnClick", function(self)
        local checked = self:GetChecked() and true or false
        options.enablePauseButton = checked

        -- Ensure SavedVariables exist and keep NS in sync
        PVPQTimerDB = PVPQTimerDB or {}
        PVPQTimerDB.global = PVPQTimerDB.global or {}

        NS.db     = PVPQTimerDB
        NS.global = PVPQTimerDB.global

        NS.global.enablePauseButton = checked

        if NS.ApplyPauseButtonConfig then
            NS.ApplyPauseButtonConfig()
        end
    end)

    --------------------------------------------------
    -- Dropdown: Pause Location
    --------------------------------------------------
    local pauseLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pauseLabel:SetPoint("TOPLEFT", cbPause, "BOTTOMLEFT", 0, -12)
    pauseLabel:SetText("Pause Location")

    local pauseDropdown = CreateFrame(
        "Frame",
        "PVPQTimerPauseLocationDropdown",
        panel,
        "UIDropDownMenuTemplate"
    )
    pauseDropdown:SetPoint("TOPLEFT", pauseLabel, "BOTTOMLEFT", -16, -4)

    local function PauseLocationDropdown_Initialize(self, level)
        local selected = options.pauseLocation or "RIGHT"

        for _, item in ipairs(pauseLocationList) do
            local info = UIDropDownMenu_CreateInfo()
            info.text  = item.text
            info.value = item.value
            info.func  = function()
                options.pauseLocation = item.value

                PVPQTimerDB = PVPQTimerDB or {}
                PVPQTimerDB.global = PVPQTimerDB.global or {}
                NS.db     = PVPQTimerDB
                NS.global = PVPQTimerDB.global

                NS.global.pauseLocation = item.value

                UIDropDownMenu_SetSelectedValue(pauseDropdown, item.value)
                UIDropDownMenu_SetText(pauseDropdown, item.text)

                if NS.ApplyPauseButtonConfig then
                    NS.ApplyPauseButtonConfig()
                end
            end
            info.checked = (item.value == selected)
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(pauseDropdown, PauseLocationDropdown_Initialize)
    UIDropDownMenu_SetWidth(pauseDropdown, 120)
    UIDropDownMenu_SetSelectedValue(pauseDropdown, options.pauseLocation or "RIGHT")
    UIDropDownMenu_SetText(
        pauseDropdown,
        (options.pauseLocation == "LEFT") and "LEFT" or "RIGHT"
    )

    --------------------------------------------------
    -- Slider: Font Size (8–20)
    --------------------------------------------------
    local slider = CreateSlider(panel, "Font Size", 8, 20, 1, -220)

    local startingSize = (NS and NS.global and NS.global.fontSize)
        or (NS and NS.FONT_SIZE)
        or options.fontSize
        or 14

    slider:SetValue(startingSize)

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        self:SetValue(value)

        if NS and NS.ApplyFontSize then
            NS.ApplyFontSize(value)
        end
    end)
end

panel:SetScript("OnShow", BuildUI)