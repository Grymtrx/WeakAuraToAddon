-- options.lua
local ADDON_NAME, NS = ...


local options = {
    enableBackground = true,
    enableMMR     = true,
    fontSize      = 13,
    grow          = "CENTER",
    anchor        = "CENTER",
}

local growList = {
    { value = "UP",   text = "UP"   },
    { value = "CENTER", text = "CENTER" },
    { value = "DOWN", text = "DOWN" },
}

local anchorList = {
    { value = "TOPLEFT",     text = "TOPLEFT"     },
    { value = "TOP",         text = "TOP"  },
    { value = "TOPRIGHT",    text = "TOPRIGHT"   },
    { value = "LEFT",        text = "LEFT" },
    { value = "CENTER",      text = "CENTER"      },
    { value = "RIGHT",       text = "RIGHT"     },
    { value = "BOTTOMLEFT",  text = "BOTTOMLEFT" },
    { value = "BOTTOM",      text = "BOTTOM"},
    { value = "BOTTOMRIGHT", text = "BOTTOMRIGHT"},
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

local function CreateSlider(parent, label, minVal, maxVal, step, yOffset)
    -- Give the slider a name only if the parent has one; otherwise leave it nil
    local parentName = parent:GetName()
    local sliderName
    if parentName then
        -- strip spaces from label to avoid weird global names
        sliderName = parentName .. label:gsub("%s+", "") .. "Slider"
    end

    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", 16, yOffset)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    -- Use the regions directly, no _G lookup needed
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


local function CreateDropdown(parent, labelText, width, yOffset)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 16, yOffset)
    label:SetText(labelText)

    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", -15, -2)
    dropdown:SetWidth(width or 150)

    return dropdown
end

--------------------------------------------------
-- Category Frame
--------------------------------------------------

local panel = CreateFrame("Frame", "PVPQTimerOptionsPanel", UIParent)
panel.name = "PVPQTimer"

-- For DF/TWW settings panel: register this frame as an AddOn category
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
        if NS.global.fontSize then
            options.fontSize = NS.global.fontSize
        end
        -- (grow/anchor/MMR can be wired later)
    end

    --------------------------------------------------
    -- Title
    --------------------------------------------------
    CreateTitle(panel, "PVPQTimer Settings", -16)

    --------------------------------------------------
    -- Checkbox: Enable Background & Border
    --------------------------------------------------
    local cbBG = CreateCheckbox(
        panel,
        "Enable Background & Border",
        "Toggle a backdrop + border for the timer (wiring later).",
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
    -- Checkbox: Enable MMR Tracking
    --------------------------------------------------
    local cbMMR = CreateCheckbox(
        panel,
        "Enable MMR Tracking",
        "When enabled, PVPQTimer will include MMR-related info in its display (wiring later).",
        -86
    )
    cbMMR:SetChecked(options.enableMMR)

    cbMMR:SetScript("OnClick", function(self)
        options.enableMMR = self:GetChecked() and true or false
        -- later: notify addon / save
    end)

    --------------------------------------------------
    -- Slider: Font Size (8–20)
    --------------------------------------------------
    local slider = CreateSlider(panel, "Font Size", 8, 20, 1, -145)

    -- Start from saved value if available, otherwise fallback
    local startingSize = (NS and NS.global and NS.global.fontSize)
        or (NS and NS.FONT_SIZE)
        or options.fontSize
        or 14

    slider:SetValue(startingSize)

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        self:SetValue(value)

        -- Apply immediately + persist
        if NS and NS.ApplyFontSize then
            NS.ApplyFontSize(value)
        end
    end)


    --------------------------------------------------
    -- Dropdown: Anchor Location
    --------------------------------------------------
    local anchorDropdown = CreateDropdown(panel, "Anchor Location", 200, -180)

    local function AnchorDropdown_Initialize(self, level)
        local selected = options.anchor

        for _, item in ipairs(anchorList) do
            local info  = UIDropDownMenu_CreateInfo()
            info.text   = item.text
            info.value  = item.value
            info.func   = function(btn)
                options.anchor = btn.value
                UIDropDownMenu_SetSelectedValue(self, btn.value)
                UIDropDownMenu_SetText(self, item.text)
                -- later: notify addon / save
            end
            info.checked = (item.value == selected)
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(anchorDropdown, AnchorDropdown_Initialize)
    UIDropDownMenu_SetWidth(anchorDropdown, 120)
    UIDropDownMenu_SetSelectedValue(anchorDropdown, options.anchor)

    local initialAnchorText = "Center"
    for _, item in ipairs(anchorList) do
        if item.value == options.anchor then
            initialAnchorText = item.text
            break
        end
    end
    UIDropDownMenu_SetText(anchorDropdown, initialAnchorText)

    --------------------------------------------------
    -- Dropdown: Grow Direction
    --------------------------------------------------
    local growDropdown = CreateDropdown(panel, "Grow Direction", 160, -240)

    local function GrowDropdown_Initialize(self, level)
        local selected = options.grow

        for _, item in ipairs(growList) do
            local info  = UIDropDownMenu_CreateInfo()
            info.text   = item.text
            info.value  = item.value
            info.func   = function(btn)
                options.grow = btn.value
                UIDropDownMenu_SetSelectedValue(self, btn.value)
                UIDropDownMenu_SetText(self, item.text)
                -- later: notify addon / save
            end
            info.checked = (item.value == selected)
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(growDropdown, GrowDropdown_Initialize)
    UIDropDownMenu_SetWidth(growDropdown, 120)
    UIDropDownMenu_SetSelectedValue(growDropdown, options.grow)
    UIDropDownMenu_SetText(growDropdown, (options.grow == "UP") and "Up" or "Down")
end


panel:SetScript("OnShow", BuildUI)