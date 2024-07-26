local addonName, addon = ...
IPAInstancePortalMapDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin);

function IPAInstancePortalMapDataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate("IPAInstancePortalPinTemplate");
end

function IPAInstancePortalMapDataProviderMixin:OnShow()
	self:RegisterEvent("CVAR_UPDATE");
end

function IPAInstancePortalMapDataProviderMixin:OnHide()
	self:UnregisterEvent("CVAR_UPDATE");
end

function IPAInstancePortalMapDataProviderMixin:OnEvent(event, ...)
	if event == "CVAR_UPDATE" then
		local eventName, value = ...;
		if eventName == "INSTANCE_PORTAL_REFRESH" then
			self:RefreshAllData();
		end
	end
end

function IPAInstancePortalMapDataProviderMixin:RefreshAllData(fromOnShow)
	self:RemoveAllData();
	IPAUIPrintDebug("IPAInstancePortalMapDataProviderMixin:RefreshAllData")

	local trackOnZones = IPAUITrackInstancePortals
	local trackOnContinents = IPAUITrackInstancePortalsOnContinents

	local mapID = self:GetMap():GetMapID();
	IPAUIPrintDebug("Map ID = "..mapID)

	local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(mapID)

	for i, dungeonEntranceInfo in ipairs(dungeonEntrances) do
		IPAUIPrintDebug("Atlas = ("..dungeonEntranceInfo["position"]["x"]..","..dungeonEntranceInfo["position"]["y"]..")")
	end

	if IPAUIPinDB[mapID] then
		local count = #IPAUIPinDB[mapID]
		local isContinent = false;
		for i = 1, #IPAUIContinentMapDB do
			if IPAUIContinentMapDB[i] == mapID then
				isContinent = true;
			end
		end

        if not (isContinent) then
            return
        end

		IPAUIPrintDebug("Map is continent = "..(isContinent and 'true' or 'false'))
		local playerFaction = UnitFactionGroup("player")

		for i = 1, count do
			local entranceInfo = IPAUIGetEntranceInfoForMapID(mapID, i);

			if entranceInfo then
				local factionWhitelist = entranceInfo["factionWhitelist"];

				local isWhitelisted = true;

				if factionWhitelist and not (factionWhitelist == playerFaction) then
					isWhitelisted = false
				end

				if (isContinent and trackOnContinents) or (not isContinent and trackOnZones) then
					if (isWhitelisted) then
						local pin = self:GetMap():AcquirePin("IPAInstancePortalPinTemplate", entranceInfo);
						pin.dataProvider = self;
					end
				end
			end
		end
	end

end

-- local function for "Add Waypoints" with the feature to "force" Built-In Waypoint System, just set "useTomTom" to false or leave it blank
local function AddNativeWaypoint(mapID, x, y)
	if C_Map.CanSetUserWaypointOnMap(mapID) then
		local vector = CreateVector2D(x, y)
		local mapPoint = UiMapPoint.CreateFromVector2D(mapID, vector)
		C_Map.SetUserWaypoint(mapPoint)
		C_SuperTrack.SetSuperTrackedUserWaypoint(true)
		PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON);
	end
end

local function AddTomTomWaypoint(mapID, x, y, title)
  if TomTom then
    title = title or "Waypoint"
    TomTom:AddWaypoint(mapID, x, y, {
      title = title,
      persistent = false,
      minimap = true,
      world = true,
      from = addonName or "InstancePortalsAdvanced"
    })
  end
end


--[[ Pin ]]--
IPAInstancePortalProviderPinMixin = BaseMapPoiPinMixin:CreateSubPin("PIN_FRAME_LEVEL_DUNGEON_ENTRANCE");

function IPAInstancePortalProviderPinMixin:OnAcquired(dungeonEntranceInfo) -- override
	BaseMapPoiPinMixin.OnAcquired(self, dungeonEntranceInfo);

	local poiInfo = self:GetPoiInfo();
	self.poiInfo = poiInfo;
	self:SetDataProvider(poiInfo.dataProvider);

	self.hub = dungeonEntranceInfo.hub
	self.tier = dungeonEntranceInfo.tier;
	self.journalInstanceID = dungeonEntranceInfo.journalInstanceID;
	self.isRaid = select(11, EJ_GetInstanceInfo(self.journalInstanceID));
end

function IPAInstancePortalProviderPinMixin:OnMouseClickAction(button)
	if (not button) then return end

	if (button == "LeftButton") then
		local useTomTom = true
		if IPASettings and IPASettings.options then
			useTomTom = IPASettings.options.useTomTom and (TomTom ~= nil) or false
		end

		local wp_mapid, wp_x, wp_y, wp_name
		IPAUIPrintDebug("IPAInstancePortalProviderPinMixin:OnMouseClickAction, button: "..tostring(button))
		IPAUIPrintDebug("IPAInstancePortalProviderPinMixin:OnMouseClickAction, self.hub: "..tostring(self.hub))

		if self.hub == 0 then
			local uiMapID = self:GetMap():GetMapID();
			IPAUIPrintDebug("uiMapID: "..uiMapID)
			if not uiMapID then return end

			local journalInstanceID = self.journalInstanceID
			IPAUIPrintDebug("self.journalInstanceID: "..journalInstanceID)
			if not journalInstanceID then return end

			-- function C_Map.GetMapChildrenInfo(uiMapID, optional mapType, optional allDescendants)
			local mapChildren = C_Map.GetMapChildrenInfo(uiMapID, Enum.UIMapType.Zone) -- get current map children
			if ( (type(mapChildren) ~= 'table') or (#mapChildren < 1) ) then return end -- mapChildren is not table or empty

			if (journalInstanceID == 1179) then -- special case "The Eternal Palace"
				local name = EJ_GetInstanceInfo(1179) or "The Eternal Palace"

				wp_mapid = 1355
				wp_x = (0.50369811058044)
				wp_y = (0.12483072280884)
				wp_name = name
			else
				for _, childMapInfo in ipairs(mapChildren) do -- enum "current" map for children
					if childMapInfo and childMapInfo.mapID then
						local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(childMapInfo.mapID); -- get Dungeon Entrances for current Map
						for _, dungeonEntranceInfo in ipairs(dungeonEntrances) do -- enum "dungeonEntrances"
							if dungeonEntranceInfo.journalInstanceID == journalInstanceID then -- found Dungeon with matching instanceID
								IPAUIPrintDebug("InstanceID: "..journalInstanceID)
								wp_mapid = childMapInfo.mapID
								wp_x = dungeonEntranceInfo.position.x
								wp_y = dungeonEntranceInfo.position.y
								wp_name = dungeonEntranceInfo.name or "Waypoint"
								IPAUIPrintDebug("childMapInfo.mapID: "..childMapInfo.mapID)
								IPAUIPrintDebug("dungeonEntranceInfo.name: "..dungeonEntranceInfo.name)
								IPAUIPrintDebug("dungeonEntranceInfo.position.x: "..dungeonEntranceInfo.position.x)
								IPAUIPrintDebug("dungeonEntranceInfo.position.y: "..dungeonEntranceInfo.position.y)
							end
						end
					end
				end
			end

			-- if anything is missing, TRY to use Pin itself as Source
			if (not wp_mapid) or (not wp_x) or (not wp_y) or (not wp_name) then
				IPAUIPrintDebug("Waypoint Info is missing, try to use PIN as Source")
				if (not wp_mapid) then IPAUIPrintDebug("Missing: wp_mapid") end
				if (not wp_x) then IPAUIPrintDebug("Missing: wp_x") end
				if (not wp_y) then IPAUIPrintDebug("Missing: wp_y") end
				if (not wp_name) then	IPAUIPrintDebug("Missing: wp_name")	end

				wp_mapid = self:GetMap():GetMapID();
				wp_x, wp_y = self:GetPosition()
				wp_name = self.name or "Waypoint"
			end

		else -- if self.hub ~= 0, try to use Map Pin itself as Source
			wp_mapid = self:GetMap():GetMapID();
			wp_x, wp_y = self:GetPosition()
			wp_name = self.name or "Waypoint"
		end

		IPAUIPrintDebug("\nWaypoint Info:\n  MapID: "..wp_mapid.."\n  X: "..wp_x.."\n  Y: "..wp_y.."\n  Name: "..wp_name.."\n  System: "..(useTomTom and "TomTom" or "Blizzard").."\n")

		if useTomTom ~= true then
			AddNativeWaypoint(wp_mapid, wp_x, wp_y)
		else
			AddTomTomWaypoint(wp_mapid, wp_x, wp_y, wp_name)
		end

	elseif (button == "RightButton") then
		EncounterJournal_LoadUI();
		EncounterJournal_OpenJournal(nil, self.journalInstanceID);
	end

end


-- Waypoint Function for Blizzard Dungeon Entrance Pins
local function WaypointDungeonEntrancePinMixin(self, button)
	if (not self) or (not button) then return end

	if (button == "LeftButton") then
		local useTomTom = true
		if IPASettings and IPASettings.options then
			useTomTom = IPASettings.options.useTomTom and (TomTom ~= nil) or false
		end		
		IPAUIPrintDebug("useTomTom: "..tostring(useTomTom))
		
		if (useTomTom == true) then
			local wp_mapid, wp_x, wp_y, wp_name
			local uiMapID = self:GetMap():GetMapID();
			local journalInstanceID = self.journalInstanceID

			local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(uiMapID);
			for i, dungeonEntranceInfo in ipairs(dungeonEntrances) do
				if dungeonEntranceInfo.journalInstanceID == journalInstanceID then
					IPAUIPrintDebug("InstanceID: "..journalInstanceID)
					wp_mapid = uiMapID
					wp_x = dungeonEntranceInfo.position.x
					wp_y = dungeonEntranceInfo.position.y
					wp_name = dungeonEntranceInfo.name or "Waypoint"
				end
			end

			-- if anything is missing, TRY to use Pin itself as Source
			if (not wp_mapid) or (not wp_x) or (not wp_y) or (not wp_name) then
				IPAUIPrintDebug("Waypoint Info is missing, try to use PIN as Source")
				if (not wp_mapid) then IPAUIPrintDebug("Missing: wp_mapid") end
				if (not wp_x) then IPAUIPrintDebug("Missing: wp_x") end
				if (not wp_y) then IPAUIPrintDebug("Missing: wp_y") end
				if (not wp_name) then	IPAUIPrintDebug("Missing: wp_name")	end

				wp_mapid = self:GetMap():GetMapID();
				wp_x, wp_y = self:GetPosition()
				wp_name = self.name or "Waypoint"
			end
			
			IPAUIPrintDebug("\nWaypoint Info:\n  MapID: "..wp_mapid.."\n  X: "..wp_x.."\n  Y: "..wp_y.."\n  Name: "..wp_name.."\n  System: "..(useTomTom and "TomTom" or "Blizzard").."\n")
			AddTomTomWaypoint(wp_mapid, wp_x, wp_y, wp_name)
		else
			-- useTomTom is NOT true, use Native Tracking system
			SuperTrackablePinMixin.OnMouseClickAction(self, button);
		end
	elseif button == "RightButton" then
		EncounterJournal_LoadUI();
		EncounterJournal_OpenJournal(nil, self.journalInstanceID);
	end
end
_G.DungeonEntrancePinMixin.OnMouseClickAction = WaypointDungeonEntrancePinMixin