local addonName, IPA = ...

_G["InstancePortalsAdv"] = IPA

local eventFrame = CreateFrame("FRAME")
eventFrame:RegisterEvent("PLAYER_LOGIN")

local SettingsRegistered = false

function IPA:CreateSettings()
	if SettingsRegistered then return end
	
	IPASettings = IPASettings and IPASettings.options and IPASettings or IPA.DefaultSettings

	local categoryMain = Settings.RegisterVerticalLayoutCategory("|rInstance Portals |cff0080ffAdvanced|r");
	categoryMain.ID = addonName
	
	local function OnSettingChanged(setting, value)
		-- This callback will be invoked whenever a setting is modified.
		local variable = setting:GetVariable();
		IPASettings["options"][variable] = value;
	end

	-- pinsOnContinentMap
	do
		local name = "Pins on Continent Map"
		local variable = addonName.."_pinsOnContinentMap"
		local tooltip = "Enable or Disable Dungeon Entrance Pins on the Continent Map"
		local variableTbl = IPASettings["options"]
		local variableKey = "pinsOnContinentMap"
		local defaultValue = IPA.DefaultSettings["options"][variableKey] or true

    local setting = Settings.RegisterAddOnSetting(categoryMain, variable, variableKey, variableTbl, Settings.VarType.Boolean, name, defaultValue)
		setting:SetValueChangedCallback(OnSettingChanged)
		Settings.CreateCheckbox(categoryMain, setting, tooltip)
	end

	-- useWaypointsZone
	do
		local name = "Waypoints on Zone Map"
		local variable = addonName.."_useWaypointsZone"
		local tooltip = "Enable or Disable Waypoint Feature on Zone Maps\n\n|r|cffff0000Warning!|r\nThis will also disable the \"native\" Waypoint function added in TWW!"
		local variableTbl = IPASettings["options"]
		local variableKey = "useWaypointsZone"
		local defaultValue = IPA.DefaultSettings["options"][variableKey] or true

    local setting = Settings.RegisterAddOnSetting(categoryMain, variable, variableKey, variableTbl, Settings.VarType.Boolean, name, defaultValue)
		setting:SetValueChangedCallback(OnSettingChanged)
		Settings.CreateCheckbox(categoryMain, setting, tooltip)
	end

	-- useWaypointsContient
	do
		local name = "Waypoints on Continent Map"
		local variable = addonName.."_useWaypointsContient"
		local tooltip = "Enable or Disable the Feature to add a Waypoint when click on a Dungeon Entrace Pin on the Contient Map"
		local variableTbl = IPASettings["options"]
		local variableKey = "useWaypointsContient"
		local defaultValue = IPA.DefaultSettings["options"][variableKey] or true

    local setting = Settings.RegisterAddOnSetting(categoryMain, variable, variableKey, variableTbl, Settings.VarType.Boolean, name, defaultValue)
		setting:SetValueChangedCallback(OnSettingChanged)
		Settings.CreateCheckbox(categoryMain, setting, tooltip)
	end


	if C_AddOns and C_AddOns.IsAddOnLoaded("TomTom") then
		-- useTomTomZone
		do
			local name = "Use TomTom for Zone Map"
			local variable = addonName.."_useTomTomZone"
			local tooltip = "Enable or Disable TomTom as Waypoint System for Zone Map\n\n\Enabled: Use TomTom\nDisabled: Use Native"
			local variableTbl = IPASettings["options"]
			local variableKey = "useTomTomZone"
			local defaultValue = IPA.DefaultSettings["options"][variableKey] or false

			local setting = Settings.RegisterAddOnSetting(categoryMain, variable, variableKey, variableTbl, Settings.VarType.Boolean, name, defaultValue)
			setting:SetValueChangedCallback(OnSettingChanged)
			Settings.CreateCheckbox(categoryMain, setting, tooltip)
		end

		-- useTomTomContinent
		do
			local name = "Use TomTom for Continent Map"
			local variable = addonName.."_useTomTomContinent"
			local tooltip = "Enable or Disable TomTom as Waypoint System for Continent Map\n\n\Enabled: Use TomTom\nDisabled: Use Native"
			local variableTbl = IPASettings["options"]
			local variableKey = "useTomTomContinent"
			local defaultValue = IPA.DefaultSettings["options"][variableKey] or false

			local setting = Settings.RegisterAddOnSetting(categoryMain, variable, variableKey, variableTbl, Settings.VarType.Boolean, name, defaultValue)
			setting:SetValueChangedCallback(OnSettingChanged)
			Settings.CreateCheckbox(categoryMain, setting, tooltip)
		end
	end

	-- debug
	do
		local name = "Debug Mode"
		local variable = addonName.."_debug"
		local tooltip = "Enable or Disable Dubug Mode\n\n\|r|cffff0000Warning!|r\nThis can overload your Chat!"
		local variableTbl = IPASettings["options"]
		local variableKey = "debug"
		local defaultValue = IPA.DefaultSettings["options"][variableKey] or true

    local setting = Settings.RegisterAddOnSetting(categoryMain, variable, variableKey, variableTbl, Settings.VarType.Boolean, name, defaultValue)
		setting:SetValueChangedCallback(OnSettingChanged)
		Settings.CreateCheckbox(categoryMain, setting, tooltip)
	end

	Settings.RegisterAddOnCategory(categoryMain)

	_G['SLASH_' .. addonName .. 'Options' .. 1] = '/ipa'
	_G['SLASH_' .. addonName .. 'Options' .. 2] = '/ipadv'
	SlashCmdList[addonName .. 'Options'] = function(msg)
		Settings.OpenToCategory(categoryMain.ID)
	end
	
	SettingsRegistered = true
end

eventFrame:SetScript("OnEvent", function(self, event, ...)
	if event == "PLAYER_LOGIN" then
		-- Create Settings on "PLAYER_LOGIN" because of TomTom Support (TomTom needs to be loaded first)
			IPA:CreateSettings()
	end
end)