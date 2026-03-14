local addonName, IPA = ...

IPA.DefaultSettings = {
    options = {
        showOwnPins = true,
        showOwnDelvePins = true,
        -- TomTom support disabled for now, re-enable when implemented
        -- useTomTom = false,
        -- useTomTomDelve = false,
    },
    version = 6,
}

local eventFrame = CreateFrame("FRAME")
eventFrame:RegisterEvent("PLAYER_LOGIN")

local SettingsRegistered = false

function CreateSettings()
    if SettingsRegistered then return end

    IPASettings = IPASettings and IPASettings.options and IPASettings or IPA.DefaultSettings

    local categoryMain = Settings.RegisterVerticalLayoutCategory("Instance Portals |cff0080ffAdvanced|r")

    local function OnSettingChanged(setting, value)
        local variable = setting:GetVariable()
        IPASettings["options"][variable] = value
    end

    -- showOwnPins
    do
        local name = "Show Own Dungeon Pins"
        local tooltip = "Enable or Disable own Dungeon Entrance Pins on Continent and Zone Maps"
        local variableTbl = IPASettings["options"]
        local variableKey = "showOwnPins"
        local defaultValue = IPA.DefaultSettings["options"][variableKey]

        local setting = Settings.RegisterAddOnSetting(categoryMain, addonName.."_"..variableKey, variableKey, variableTbl, Settings.VarType.Boolean, name, defaultValue)
        Settings.SetOnValueChangedCallback(variableKey, OnSettingChanged)
        Settings.CreateCheckbox(categoryMain, setting, tooltip)
    end

    -- showOwnDelvePins
    do
        local name = "Show Own Delve Pins"
        local tooltip = "Enable or Disable own Delve Entrance Pins on Continent and Zone Maps"
        local variableTbl = IPASettings["options"]
        local variableKey = "showOwnDelvePins"
        local defaultValue = IPA.DefaultSettings["options"][variableKey]

        local setting = Settings.RegisterAddOnSetting(categoryMain, addonName.."_"..variableKey, variableKey, variableTbl, Settings.VarType.Boolean, name, defaultValue)
        Settings.SetOnValueChangedCallback(variableKey, OnSettingChanged)
        Settings.CreateCheckbox(categoryMain, setting, tooltip)
    end

    --[[ TomTom support - disabled for now
    if C_AddOns and C_AddOns.IsAddOnLoaded("TomTom") then

        -- useTomTom
        do
            local name = "Use TomTom for Dungeon Pins"
            local tooltip = "Enable or Disable TomTom as Waypoint System for Dungeon Pins\n\nEnabled: Use TomTom\nDisabled: Use Native"
            local variableTbl = IPASettings["options"]
            local variableKey = "useTomTom"
            local defaultValue = IPA.DefaultSettings["options"][variableKey]

            local setting = Settings.RegisterAddOnSetting(categoryMain, addonName.."_"..variableKey, variableKey, variableTbl, Settings.VarType.Boolean, name, defaultValue)
            Settings.SetOnValueChangedCallback(variableKey, OnSettingChanged)
            Settings.CreateCheckbox(categoryMain, setting, tooltip)
        end

        -- useTomTomDelve
        do
            local name = "Use TomTom for Delve Pins"
            local tooltip = "Enable or Disable TomTom as Waypoint System for Delve Pins\n\nEnabled: Use TomTom\nDisabled: Use Native"
            local variableTbl = IPASettings["options"]
            local variableKey = "useTomTomDelve"
            local defaultValue = IPA.DefaultSettings["options"][variableKey]

            local setting = Settings.RegisterAddOnSetting(categoryMain, addonName.."_"..variableKey, variableKey, variableTbl, Settings.VarType.Boolean, name, defaultValue)
            Settings.SetOnValueChangedCallback(variableKey, OnSettingChanged)
            Settings.CreateCheckbox(categoryMain, setting, tooltip)
        end

    end
    ]]

    Settings.RegisterAddOnCategory(categoryMain)

    local categoryID = categoryMain.ID

    _G['SLASH_' .. addonName .. 'Options' .. 1] = '/ipa'
    _G['SLASH_' .. addonName .. 'Options' .. 2] = '/ipadv'
    SlashCmdList[addonName .. 'Options'] = function(msg)
        Settings.OpenToCategory(categoryID)
    end

    SettingsRegistered = true
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        CreateSettings()
    end
end)