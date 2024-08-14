local addonName, IPA = ...

IPA.DefaultSettings = {
  options = {
    debug = false,
		pinsOnContinentMap = true,
		useWaypointsContient = true,
		useWaypointsZone = true,
    useTomTomZone = false,
    useTomTomContinent = false,
  },
  version = 3,
}

local function CreateDatabase()
  if (not IPASettings) or (IPASettings == nil) then IPASettings = IPA.DefaultSettings end
end

local function ReCreateDatabase()
  IPASettings = IPA.DefaultSettings
end

function IPAUIPrintDebug(debugtext, force)
  if (IPASettings and IPASettings.options and IPASettings.options.debug == true) or (force == true) then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff8000IPADebug\[|r"..debugtext.."|cffff8000\]")
  end
end

if not IPASettings then
  CreateDatabase()
  IPAUIPrintDebug("Database: Create default Database because empty")
end

-- check if "value {v}" already exists in "table {t}"
function InstancePortalAdv_tableContains(t, v)
    for _, item in ipairs(t) do
        if item == v then
            return true
        end
    end
    return false
end

function InstancePortalAdvUI_OnLoad(self)
	--LoadAddOn("Blizzard_WorldMap")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	IPAUIPrintDebug("InstancePortalAdvUI_OnLoad()")
	WorldMapFrame:AddDataProvider(CreateFromMixins(IPAInstancePortalMapDataProviderMixin));
end

function InstancePortalAdvUI_OnEvent(event, arg1)
	if event == "PLAYER_ENTERING_WORLD" then
		if IPASettings then
			if not (IPASettings.version) then
				IPAUIPrintDebug("Settings Error Instance Portal Advanced Settings will resetted!", true)
				IPAUIPrintDebug("Use the NEW Settings Page at \"Options >> AddOns\" from now on.", true)
				ReCreateDatabase()
			elseif IPASettings.version and IPASettings.version < IPA.DefaultSettings.version then
				-- do something if "Database Version" is an older version and maybe need attention?!
				IPAUIPrintDebug("Old Database found, Instance Portal Advanced Settings will resetted!", true)
				IPAUIPrintDebug("Use the NEW Settings Page at \"Options >> AddOns\" from now on.", true)
				ReCreateDatabase()
			end
		end
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
			local entranceInfo = {};
						
			entranceInfo["areaPoiID"] = 0
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
			
			local mapChildren = C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone) -- get current map children
			
			for _, childMapInfo in ipairs(mapChildren) do -- enum "current" map for children
				if childMapInfo and childMapInfo.mapID then
					local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(childMapInfo.mapID);
					for _, dungeonEntranceInfo in ipairs(dungeonEntrances) do -- enum "dungeonEntrances"
						if dungeonEntranceInfo.journalInstanceID == subInstanceMapIDs[1] then
							entranceInfo["areaPoiID"] = dungeonEntranceInfo.areaPoiID -- use FIRST instanceID for Supertracking!
						end
					end
				end
			end

			IPAUIPrintDebug("Hub: " .. entranceInfo["name"]);

			return entranceInfo
		end

		local m = 1
		if desired_IPAUIInstanceMapDB[subInstanceMapIDs[m]] then
			local name = desired_IPAUIInstanceMapDB[subInstanceMapIDs[m]][1]
			local type = desired_IPAUIInstanceMapDB[subInstanceMapIDs[m]][2]
			local requiredLevel = desired_IPAUIInstanceMapDB[subInstanceMapIDs[m]][3]

			local tier = desired_IPAUIInstanceMapDB[subInstanceMapIDs[m]][4]

			local entranceInfo = {};

			
			entranceInfo["areaPoiID"] = 0
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
			
			--print(tostring(mapID))
			local mapChildren = C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone) -- get current map children
			
			for _, childMapInfo in ipairs(mapChildren) do -- enum "current" map for children
				if childMapInfo and childMapInfo.mapID then
					local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(childMapInfo.mapID);
					for _, dungeonEntranceInfo in ipairs(dungeonEntrances) do -- enum "dungeonEntrances"
						if dungeonEntranceInfo.journalInstanceID == instanceID then
							entranceInfo["areaPoiID"] = dungeonEntranceInfo.areaPoiID
						end
					end
				end
			end

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


--[[
-- Slash Commands for "Config" until i maybe or not add an Optionsframe ;)
_G.SLASH_IPASETTINGS1 = '/ipa'
_G.SLASH_IPASETTINGS2 = '/ipadv'
SlashCmdList.IPASETTINGS = function(msg)
  if not msg or type(msg) ~= "string" or msg == "" or msg == "help" then
    print("|cffff8000\nInstane Portals Advanced Usage:\n|r==========================================================\n|cffff8000/ipa|r or |cffff8000/ipa help|r - Show this message\n|cffff8000/ipa waypoints|r - Toggle \"Waypoint Feature\"\n|cffff8000/ipa tomtom|r - Toggle \"Use TomTom as Waypoint System\"\n|cffff8000/ipa zone|r - Toggle \"Dungeon Entraces on Zone Map\"\n|cffff8000/ipa cont|r - Toggle \"Dungeon Entraces on Continent Map\"\n|r==========================================================")
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
]]