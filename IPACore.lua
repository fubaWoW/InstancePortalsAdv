local DefaultSettings = {
  options = {
    debug = false,
		useWaypoints = true,
    useTomTom = true,
  },
  version = 1,
}

local function CreateDatabase()
  if (not IPASettings) or (IPASettings == nil) then IPASettings = DefaultSettings end
end

local function ReCreateDatabase()
  IPASettings = DefaultSettings
end

function IPAUIPrintDebug(debugtext)
  if IPASettings and IPASettings.options and IPASettings.options.debug then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8000IPADebug\[|r"..debugtext.."|cffff8000\]")
  end
end

if not IPASettings then
  CreateDatabase()
  IPAUIPrintDebug("Database: Create default Database because empty")
end

if IPASettings.version and IPASettings.version < DefaultSettings.version then
  -- do something if "Database Version" is an older version and maybe need attention?!
  IPAUIPrintDebug("Database: Old version found")
end

function InstancePortalAdvUI_OnLoad(self)
	LoadAddOn("Blizzard_WorldMap")
	self:RegisterEvent("ADDON_LOADED")

	IPAUIPrintDebug("InstancePortalAdvUI_OnLoad()")
	WorldMapFrame:AddDataProvider(CreateFromMixins(IPAInstancePortalMapDataProviderMixin));
	hooksecurefunc("ToggleDropDownMenu", IPAUIDropDownInit)

end

function InstancePortalAdvUI_OnEvent(event, arg1)
	if event == "ADDON_LOADED" then
		if IPAUITrackInstancePortals == nil then
			IPAUIPrintDebug("IPUISetDefaults()")
			IPAUITrackInstancePortals = true
			IPAUITrackInstancePortalsOnContinents = true
		end

		IPAUIPrintDebug("ADDON_LOADED()")

		RegisterCVar("IPAUITrackInstancePortals")
		RegisterCVar("IPAUITrackInstancePortalsOnContinents")
	end
end

function IPAUIDropDownInit(_, _, dropDownFrame, _, _, _, _, clickedButton)
	local trackingOptionsFrame = WorldMapFrame.overlayFrames[2]
	local trackingOptionsMenu = trackingOptionsFrame.DropDown

	IPAUIPrintDebug("IPAUIDropDownInit")

	local function OnSelection(button)
		if button.value == "IPAUITrackInstancePortals" then
			IPAUITrackInstancePortals = button.checked
		else
			IPAUITrackInstancePortalsOnContinents = button.checked
		end

		SetCVar(button.value, button.checked and "1" or "0", "INSTANCE_PORTAL_REFRESH");
		WorldMapFrame:RefreshAllDataProviders()
	end

	if dropDownFrame == trackingOptionsMenu then

		local info = UIDropDownMenu_CreateInfo();

		UIDropDownMenu_AddSeparator();
		info.isTitle = true;
		info.notCheckable = true;
		info.text = DUNGEONS.." / "..RAIDS;
		info.isNotRadio = true;
		UIDropDownMenu_AddButton(info);

		info = UIDropDownMenu_CreateInfo();
		info.isTitle = nil;
		info.notCheckable = nil;
		info.text = "Show on Zone Map"; --BATTLEFIELD_MINIMAP
		info.isNotRadio = true;
		info.checked = IPAUITrackInstancePortals;
		info.func = OnSelection;
		info.keepShownOnClick = true;
		info.value = "IPAUITrackInstancePortals";
		--UIDropDownMenu_AddButton(info);

		info = UIDropDownMenu_CreateInfo();
		info.isTitle = nil;
		info.notCheckable = nil;
		info.text = "Show on Continent Map"; --WORLD_MAP
		info.isNotRadio = true;
		info.checked = IPAUITrackInstancePortalsOnContinents;
		info.func = OnSelection;
		info.keepShownOnClick = true;
		info.value = "IPAUITrackInstancePortalsOnContinents";
		UIDropDownMenu_AddButton(info);
	end
end

function IPAUIGetEntranceInfoForMapID(mapID, i)

		instancePortal = IPAUIPinDB[mapID][i]
		if not (instancePortal) then
			IPAUIPrintDebug("No instances for map: "..mapID)
			return nil
		end

		local x = instancePortal[1]/100
		local y = instancePortal[2]/100
		local subInstanceMapIDs = instancePortal[3]
		local hubName = instancePortal[4]
		local factionWhitelist = nil
		local desired_IPAUIInstanceMapDB = IPAUIInstanceMapDB;
		local playerFaction = UnitFactionGroup("player")

		if hubName == "FactionSpecific" then
			factionWhitelist = playerFaction;
			desired_IPAUIInstanceMapDB = IPAUIInstanceFactionSpecificDB[factionWhitelist];
			hubName = nil
		elseif hubName == "Alliance" or hubName == "Horde" then
			factionWhitelist = hubName;
			desired_IPAUIInstanceMapDB = IPAUIInstanceFactionSpecificDB[factionWhitelist];
			hubName = nil
		end

		if hubName then
			entranceInfo = {};

			entranceInfo["areaPoiID"] = C_AreaPoiInfo.GetAreaPOIForMap(mapID)[0];
			entranceInfo["position"] = CreateVector2D(x, y);
			entranceInfo["name"] = hubName;

			local description = "";
			local dungeonCount = 0
			local raidCount = 0

			for m = 1, #subInstanceMapIDs do
				local instanceID = subInstanceMapIDs[m]
				local localizedName = EJ_GetInstanceInfo(instanceID);
				local requiredLevel = desired_IPAUIInstanceMapDB[subInstanceMapIDs[m]][3]
				local dungonType = desired_IPAUIInstanceMapDB[subInstanceMapIDs[m]][2];

				if dungonType == 1 then
					dungeonCount=dungeonCount+1
					description = description..localizedName.." |cFF888888("..LFG_TYPE_DUNGEON..")|r\n"
				else
					raidCount=raidCount+1
					description = description..localizedName.." |cFF888888("..LFG_TYPE_RAID..")|r\n"
				end
			end

			entranceInfo["description"] = description;

			if dungeonCount > raidCount then
				entranceInfo["atlasName"] = "Dungeon";
			else
				entranceInfo["atlasName"] = "Raid";
			end

			entranceInfo["journalInstanceID"] = 0;
			entranceInfo["hub"] = 1;
			entranceInfo["factionWhitelist"] = factionWhitelist;

			IPAUIPrintDebug("Hub: " .. entranceInfo["name"]);

			return entranceInfo
		end

		local m = 1
		if desired_IPAUIInstanceMapDB[subInstanceMapIDs[m]] then
			local name = desired_IPAUIInstanceMapDB[subInstanceMapIDs[m]][1]
			local type = desired_IPAUIInstanceMapDB[subInstanceMapIDs[m]][2]
			local requiredLevel = desired_IPAUIInstanceMapDB[subInstanceMapIDs[m]][3]

			local tier = desired_IPAUIInstanceMapDB[subInstanceMapIDs[m]][4]

			entranceInfo = {};

			entranceInfo["areaPoiID"] = C_AreaPoiInfo.GetAreaPOIForMap(mapID)[0];
			entranceInfo["position"] = CreateVector2D(x, y);
			if (type == 1) then
				entranceInfo["atlasName"] = "Dungeon";
				entranceInfo["description"] = LFG_TYPE_DUNGEON;
			else
				entranceInfo["atlasName"] = "Raid";
				entranceInfo["description"] = LFG_TYPE_RAID;
			end

			EJ_SelectTier(tier)
			local instanceID = subInstanceMapIDs[m]

			local localizedName = EJ_GetInstanceInfo(instanceID);

			entranceInfo["name"] = localizedName.."|r";

			entranceInfo["journalInstanceID"] = instanceID;
			entranceInfo["tier"] = tier;
			entranceInfo["hub"] = 0;
			entranceInfo["factionWhitelist"] = factionWhitelist;

			IPAUIPrintDebug("Instance: " .. entranceInfo["name"].." id:"..instanceID);

			return entranceInfo
		end
end

--[[
SetCVar(button.value, button.checked and "1" or "0", "INSTANCE_PORTAL_REFRESH");
WorldMapFrame:RefreshAllDataProviders()
IPAUITrackInstancePortals = true
IPAUITrackInstancePortalsOnContinents = true

RegisterCVar("IPAUITrackInstancePortals")
RegisterCVar("IPAUITrackInstancePortalsOnContinents")

/dump GetCVar("IPAUITrackInstancePortals")
]]

-- Slash Commands for "Config" until i maybe or not add an Optionsframe ;)
_G.SLASH_IPASETTINGS1 = '/ipa'
_G.SLASH_IPASETTINGS2 = '/ipadv'
SlashCmdList.IPASETTINGS = function(msg)
  if not msg or type(msg) ~= "string" or msg == "" or msg == "help" then
    print("|cffff8000\nInstane Portals Advanced Usage:\n|r==========================================================\n|cffff8000/ipa|r or |cffff8000/ipa help|r - Show this message\n|cffff8000/ipa waypoints|r - Toggle \"Waypoint Feature\"\n|cffff8000/ipa tomtom|r - Toggle \"Use TomTom as Waypoint\"\n|cffff8000/ipa zone|r - Toggle \"Dungeon Entraces on Zone Map\"\n|cffff8000/ipa cont|r - Toggle \"Dungeon Entraces on Continent Map\"\n|r==========================================================")
    return
  end
  local cmd, arg = strsplit(" ", msg:trim():lower()) -- Try splitting by space

  if cmd == "waypoints" then
    if IPASettings.options.useWaypoints then
      IPASettings.options.useWaypoints = false
      print("|cffff8000[Instance Portal Advanced]|r Use Waypoint Feature: |cffFF0000Disabled|r")
    else
      IPASettings.options.useWaypoints = true
			print("|cffff8000[Instance Portal Advanced]|r Use Waypoint Feature: |cff00FF00Enabled|r")
    end
  elseif cmd == "tomtom" then
    if IPASettings.options.useTomTom then
      IPASettings.options.useTomTom = false
      print("|cffff8000[Instance Portal Advanced]|r Use TomTom: |cffFF0000Disabled|r")
    else
      IPASettings.options.useTomTom = true
      print("|cffff8000[Instance Portal Advanced]|r Use TomTom: |cff00FF00Enabled|r")
    end
	elseif cmd == "zone" then
		if GetCVar("showDungeonEntrancesOnMap") == "1" then
			SetCVar("showDungeonEntrancesOnMap", "0")
			WorldMapFrame:RefreshAllDataProviders()
			print("|cffff8000[Instance Portal Advanced]|r Show Entrances on Zone Map: |cffFF0000Disabled|r")
		else
			SetCVar("showDungeonEntrancesOnMap", "1")
			WorldMapFrame:RefreshAllDataProviders()
			print("|cffff8000[Instance Portal Advanced]|r Show Entrances on Zone Map: |cff00FF00Enabled|r")
		end
	elseif cmd == "continent" or cmd == "cont" then
		if IPAUITrackInstancePortalsOnContinents == true then
			IPAUITrackInstancePortalsOnContinents = false
			WorldMapFrame:RefreshAllDataProviders()
			print("|cffff8000[Instance Portal Advanced]|r Show Entrances on Continent Map: |cffFF0000Disabled|r")
		else
			IPAUITrackInstancePortalsOnContinents = true
			WorldMapFrame:RefreshAllDataProviders()
			print("|cffff8000[Instance Portal Advanced]|r Show Entrances on Continent Map: |cff00FF00Enabled|r")
		end

  elseif cmd == "debug" then
    if IPASettings.options.debug then
      IPASettings.options.debug = false
			print("|cffff8000[Instance Portal Advanced]|r Debug Messages: |cffFF0000Disabled|r")
    else
      IPASettings.options.debug = true
			print("|cffff8000[Instance Portal Advanced]|r Debug Messages: |cff00FF00Enabled|r")
    end
  elseif cmd == "developer" and arg and arg == "rdb" then
    ReCreateDatabase()
		print("|cffff8000[Instance Portal Advanced]|r Reseted Databse to Default")
  end
end