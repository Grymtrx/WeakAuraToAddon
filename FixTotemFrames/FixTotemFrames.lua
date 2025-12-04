local ADDON_NAME = ...

local MAX_TOTEM_SLOTS = 4
local BUTTON_PREFIX = "TotemFrameTotem"

local function ensureTotemButtons()
    for slot = 1, MAX_TOTEM_SLOTS do
        local name = BUTTON_PREFIX .. slot
        if not _G[name] then
            local button = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
            button:SetAttribute("type", "destroytotem")
            button:SetAttribute("totem-slot", slot)
            button:Hide()
        end
    end
end

ensureTotemButtons()
