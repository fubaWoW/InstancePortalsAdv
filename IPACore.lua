local IPAUIDebug=false

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

function IPAUIPrintDebug(t)
	if (IPAUIDebug) then
		print(t)
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
