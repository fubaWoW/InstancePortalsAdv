local addonName, IPA = ...

_G["InstancePortalsAdv"] = IPA

local eventFrame = CreateFrame("FRAME")
eventFrame:RegisterEvent("PLAYER_LOGIN")

IPASettings = IPASettings or {}

local SettingsRegistered = false

function IPA:CreateSettings()
	if SettingsRegistered then return end
	
	local function OnSettingChanged(_, setting, value)
		local variable = setting:GetVariable();
		IPASettings["options"][variable] = value;
	end

	local categoryMain = Settings.RegisterVerticalLayoutCategory("|rInstance Portals |cff0080ffAdvanced|r");
	categoryMain.ID = addonName


	-- pinsOnContinentMap
	do
		local name = "Pins on Continent Map"
		local variable = "pinsOnContinentMap"
		local tooltip = "Enable or Disable Dungeon Entrance Pins on the Continent Map"
		local value = IPASettings["options"][variable]
		local defaultValue = value == nil and true or value

		local setting = Settings.RegisterAddOnSetting(categoryMain, name, variable, type(defaultValue), defaultValue)
		Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
		Settings.CreateCheckbox(categoryMain, setting, tooltip)
	end

	-- useWaypointsZone
	do
		local name = "Waypoints on Zone Map"
		local variable = "useWaypointsZone"
		local tooltip = "Enable or Disable Waypoint Feature on Zone Maps\n\n|r|cffff0000Warning!|r\nThis will also disable the \"native\" Waypoint function added in TWW!"
		local value = IPASettings["options"][variable]
		local defaultValue = value == nil and true or value

		local setting = Settings.RegisterAddOnSetting(categoryMain, name, variable, type(defaultValue), defaultValue)
		Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
		Settings.CreateCheckbox(categoryMain, setting, tooltip)
	end

	-- useWaypointsContient
	do
		local name = "Waypoints on Continent Map"
		local variable = "useWaypointsContient"
		local tooltip = "Enable or Disable the Feature to add a Waypoint when click on a Dungeon Entrace Pin on the Contient Map"
		local value = IPASettings["options"][variable]
		local defaultValue = value == nil and true or value

		local setting = Settings.RegisterAddOnSetting(categoryMain, name, variable, type(defaultValue), defaultValue)
		Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
		Settings.CreateCheckbox(categoryMain, setting, tooltip)
	end


	if IsAddOnLoaded("TomTom") then
		-- useTomTomZone
		do
			local name = "Use TomTom for Zone Map"
			local variable = "useTomTomZone"
			local tooltip = "Enable or Disable TomTom as Waypoint System for Zone Map\n\n\Enabled: Use TomTom\nDisabled: Use Native"
			local value = IPASettings["options"][variable]
			local defaultValue = value == nil and true or value


			local setting = Settings.RegisterAddOnSetting(categoryMain, name, variable, type(defaultValue), defaultValue)
			Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
			Settings.CreateCheckbox(categoryMain, setting, tooltip)
		end

		-- useTomTomContinent
		do
			local name = "Use TomTom for Continent Map"
			local variable = "useTomTomContinent"
			local tooltip = "Enable or Disable TomTom as Waypoint System for Continent Map\n\n\Enabled: Use TomTom\nDisabled: Use Native"
			local value = IPASettings["options"][variable]
			local defaultValue = value == nil and true or value

			local setting = Settings.RegisterAddOnSetting(categoryMain, name, variable, type(defaultValue), defaultValue)
			Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
			Settings.CreateCheckbox(categoryMain, setting, tooltip)
		end
	end

	-- debug
	do
		local name = "Debug Mode"
		local variable = "debug"
		local tooltip = "Enable or Disable Dubug Mode\n\n\|r|cffff0000Warning!|r\nThis can overload your Chat!"
		local value = IPASettings["options"][variable]
		local defaultValue = value == nil and true or value

		local setting = Settings.RegisterAddOnSetting(categoryMain, name, variable, type(defaultValue), defaultValue)
		Settings.SetOnValueChangedCallback(variable, OnSettingChanged)
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