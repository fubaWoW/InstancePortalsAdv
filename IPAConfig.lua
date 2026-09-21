local addonName, IPA = ...

IPA.DefaultSettings = {
    options = {
        showOwnPins = true,
        showOwnDelvePins = true,
        showOwnMinimapPins = false,
        disableNativeDungeonWaypoints = true,
        disableNativeDelveWaypoints = true,
        -- TomTom support disabled for now, re-enable when implemented
        -- useTomTom = false,
        -- useTomTomDelve = false,
    },
    version = 7,
}

local eventFrame = CreateFrame("FRAME")
eventFrame:RegisterEvent("PLAYER_LOGIN")

local SettingsRegistered = false

local function RefreshWorldMapPins()
    if IPA and IPA.NotifyUpdate then
        IPA:NotifyUpdate()
    end
end

function CreateSettings()
    if SettingsRegistered then return end

    IPASettings = IPASettings and IPASettings.options and IPASettings or IPA.DefaultSettings

    local categoryMain = Settings.RegisterVerticalLayoutCategory("Instance Portals |cff0080ffAdvanced|r")

    local function OnSettingChanged(setting, value)
        local variable = setting:GetVariable()
        IPASettings["options"][variable] = value

        RefreshWorldMapPins()
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

    -- showOwnMinimapPins
    do
        local name = "Show Own Minimap Pins"
        local tooltip = "Enable or Disable own Dungeon and Delve Pins on the Minimap\nRequires the Minimap to be updated -> move around or reload the interface"
        local variableTbl = IPASettings["options"]
        local variableKey = "showOwnMinimapPins"
        local defaultValue = IPA.DefaultSettings["options"][variableKey]

        local setting = Settings.RegisterAddOnSetting(categoryMain, addonName.."_"..variableKey, variableKey, variableTbl, Settings.VarType.Boolean, name, defaultValue)
        Settings.SetOnValueChangedCallback(variableKey, OnSettingChanged)
        Settings.CreateCheckbox(categoryMain, setting, tooltip)
    end
	
	-- disableNativeDungeonWaypoints
    -- do
        -- local name = "Disable Native Dungeon Pins"
        -- local tooltip = "Disable Blizzard's native Dungeon waypoints on login. Instance Portals Advanced handles Dungeon pins instead to prevent duplicate Dungeon icons on the map."
        -- local variableTbl = IPASettings["options"]
        -- local variableKey = "disableNativeDungeonWaypoints"
        -- local defaultValue = IPA.DefaultSettings["options"][variableKey]

        -- local setting = Settings.RegisterAddOnSetting(categoryMain, addonName.."_"..variableKey, variableKey, variableTbl, Settings.VarType.Boolean, name, defaultValue)
        -- Settings.SetOnValueChangedCallback(variableKey, OnSettingChanged)
        -- Settings.CreateCheckbox(categoryMain, setting, tooltip)
    -- end
	
    -- disableNativeDelveWaypoints
    -- do
        -- local name = "Disable Native Delve Pins"
        -- local tooltip = "Disable Blizzard's native Delve waypoints on login. Instance Portals Advanced handles Delve pins instead to prevent duplicate Delve icons on the map."
        -- local variableTbl = IPASettings["options"]
        -- local variableKey = "disableNativeDelveWaypoints"
        -- local defaultValue = IPA.DefaultSettings["options"][variableKey]

        -- local setting = Settings.RegisterAddOnSetting(categoryMain, addonName.."_"..variableKey, variableKey, variableTbl, Settings.VarType.Boolean, name, defaultValue)
        -- Settings.SetOnValueChangedCallback(variableKey, OnSettingChanged)
        -- Settings.CreateCheckbox(categoryMain, setting, tooltip)
    -- end

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

---------------------------------------------------------------------
-- Add Worldmap Filter Buttons if Client is Retail
---------------------------------------------------------------------



local function SetWorldMapPinSetting(variableKey, value)
    if not IPASettings or not IPASettings.options then
        return
    end

    IPASettings.options[variableKey] = value
    RefreshWorldMapPins()
end

local function AddButtonToWorldMapMenu()
    if not Menu then return end
    if not MenuUtil then return end

    local dungeonButton = MenuUtil.CreateCheckbox(
        "Show Own Dungeon Pins",
        function()
            return IPASettings
                and IPASettings.options
                and IPASettings.options.showOwnPins
                or false
        end,
        function()
            local current = IPASettings
                and IPASettings.options
                and IPASettings.options.showOwnPins
                or false

            SetWorldMapPinSetting("showOwnPins", not current)
        end
    )

    local delveButton = MenuUtil.CreateCheckbox(
        "Show Own Delve Pins",
        function()
            return IPASettings
                and IPASettings.options
                and IPASettings.options.showOwnDelvePins
                or false
        end,
        function()
            local current = IPASettings
                and IPASettings.options
                and IPASettings.options.showOwnDelvePins
                or false

            SetWorldMapPinSetting("showOwnDelvePins", not current)
        end
    )

    Menu.ModifyMenu("MENU_WORLD_MAP_TRACKING", function(ownerRegion, rootDescription, contextData)
        rootDescription:CreateDivider()
        rootDescription:CreateTitle("Instance Portals Advanced")
        rootDescription:Insert(dungeonButton)
        rootDescription:Insert(delveButton)
    end)
end

local isRetail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE

if isRetail then
    AddButtonToWorldMapMenu()
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        CreateSettings()

        -- if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
            -- and IPASettings
            -- and IPASettings.options
            -- and IPASettings.options.disableNativeDelveWaypoints then
            -- SetCVar("showDelveEntrancesOnMap", "0")
        -- end
		
		-- if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
            -- and IPASettings
            -- and IPASettings.options
            -- and IPASettings.options.disableNativeDungeonWaypoints then
            -- SetCVar("showDungeonEntrancesOnMap", "0")
        -- end
    end
end)