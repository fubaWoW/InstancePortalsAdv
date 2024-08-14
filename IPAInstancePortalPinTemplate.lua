local addonName, IPA = ...

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
		if eventName == "showDungeonEntrancesOnMap" then
			self:RefreshAllData();
		end
	end
end

function IPAInstancePortalMapDataProviderMixin:RefreshAllData(fromOnShow)
	self:RemoveAllData();

	IPAUIPrintDebug("IPAInstancePortalMapDataProviderMixin:RefreshAllData")

	local showDungeonEntrancesOnMap = C_CVar and C_CVar.GetCVarBool("showDungeonEntrancesOnMap") or false
	IPAUIPrintDebug("showDungeonEntrancesOnMap: "..tostring(showDungeonEntrancesOnMap))
	if not showDungeonEntrancesOnMap then return end

	local pinsOnContinentMap = IPASettings and IPASettings.options.pinsOnContinentMap
	pinsOnContinentMap = pinsOnContinentMap == nil and false or pinsOnContinentMap
	IPAUIPrintDebug("pinsOnContinentMap: "..tostring(pinsOnContinentMap))
	if not pinsOnContinentMap then return end

	local uiMapID = self:GetMap():GetMapID();
	IPAUIPrintDebug("uiMapID: "..tostring(uiMapID))
	if not uiMapID then return end

	local mapInfo = C_Map.GetMapInfo(uiMapID);
	IPAUIPrintDebug("mapInfo.mapType: "..tostring(mapInfo.mapType))
	if not mapInfo then return end
	if mapInfo.mapType ~= Enum.UIMapType.Continent then return end

	-- special case: Ny'alotha, the Waking City
	if (uiMapID == 12) or (uiMapID == 424) then
		local mapChildren = C_Map.GetMapChildrenInfo(uiMapID, Enum.UIMapType.Zone) -- get current map children
		if ( (type(mapChildren) == 'table') or (#mapChildren > 0) ) then -- mapChildren is table amd not empty
			for _, childMapInfo in ipairs(mapChildren) do -- enum "current" map for children
				if childMapInfo and childMapInfo.mapID and (childMapInfo.mapID == 1527 or childMapInfo.mapID == 1530) then
					local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(childMapInfo.mapID); -- get Dungeon Entrances for current Map
					for _, dungeonEntranceInfo in ipairs(dungeonEntrances) do -- enum "dungeonEntrances"
						if dungeonEntranceInfo.journalInstanceID == 1180 then -- Ny'alotha, the Waking City
							local entranceInfo = {}

							entranceInfo.areaPoiID = dungeonEntranceInfo.areaPoiID
							local pos_vector = CreateVector2D(dungeonEntranceInfo.position.x, dungeonEntranceInfo.position.y)
							if pos_vector then
								local continentID, worldPosition = C_Map.GetWorldPosFromMapPos(childMapInfo.mapID, pos_vector)
								if continentID and worldPosition then
									local _, mapPosition = C_Map.GetMapPosFromWorldPos(continentID, worldPosition)
									entranceInfo.position = CreateVector2D(mapPosition.x, mapPosition.y)
								end
							end

							entranceInfo.name = dungeonEntranceInfo.name
							entranceInfo.description = dungeonEntranceInfo.description
							entranceInfo.journalInstanceID = dungeonEntranceInfo.journalInstanceID
							entranceInfo.atlasName = dungeonEntranceInfo.atlasName

							local pin = self:GetMap():AcquirePin("IPAInstancePortalPinTemplate", entranceInfo);
							pin.dataProvider = self;
							pin:SetSuperTracked(false)

							if C_SuperTrack.IsSuperTrackingMapPin() then
								local areaPoiID = pin.poiInfo.areaPoiID or 0;
								local superTrackedMapPinType, superTrackedMapPinTypeID = C_SuperTrack.GetSuperTrackedMapPin()
								if (superTrackedMapPinType == Enum.SuperTrackingMapPinType.AreaPOI) and (areaPoiID == superTrackedMapPinTypeID) then
									pin:SetSuperTracked(true)
								end
							end

						end
					end
				end
			end
		end
	end

	-- special case: Antorus, The Burning Throne and Seat of the Triumvirate (Broken Isles Continent Map)
	-- this is just temporary and will get changed soon... hopefuilly! :D	
	if (uiMapID == 619) then
		local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(882); -- Zone: Eredat		
		for _, dungeonEntranceInfo in ipairs(dungeonEntrances) do
			if dungeonEntranceInfo.journalInstanceID == 945 then -- Seat of the Triumvirate
				local entranceInfo = {}
				entranceInfo.areaPoiID = dungeonEntranceInfo.areaPoiID
				
				entranceInfo.position = CreateVector2D(90/100, 10/100) -- fixed value (for now?)
				
				entranceInfo.name = dungeonEntranceInfo.name
				entranceInfo.description = dungeonEntranceInfo.description
				entranceInfo.journalInstanceID = dungeonEntranceInfo.journalInstanceID
				entranceInfo.atlasName = dungeonEntranceInfo.atlasName
				
				local pin = self:GetMap():AcquirePin("IPAInstancePortalPinTemplate", entranceInfo);
				pin.dataProvider = self;
				pin:SetSuperTracked(false)

				if C_SuperTrack.IsSuperTrackingMapPin() then
					local areaPoiID = pin.poiInfo.areaPoiID or 0;
					local superTrackedMapPinType, superTrackedMapPinTypeID = C_SuperTrack.GetSuperTrackedMapPin()
					if (superTrackedMapPinType == Enum.SuperTrackingMapPinType.AreaPOI) and (areaPoiID == superTrackedMapPinTypeID) then
						pin:SetSuperTracked(true)
					end
				end
			end
		end
		
		dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(885); -- Zone: Antoran Wastes
		for _, dungeonEntranceInfo in ipairs(dungeonEntrances) do
			if dungeonEntranceInfo.journalInstanceID == 946 then -- Seat of the Triumvirate
				local entranceInfo = {}
				entranceInfo.areaPoiID = dungeonEntranceInfo.areaPoiID
				
				entranceInfo.position = CreateVector2D(83/100, 22/100) -- fixed value (for now?)
				
				entranceInfo.name = dungeonEntranceInfo.name
				entranceInfo.description = dungeonEntranceInfo.description
				entranceInfo.journalInstanceID = dungeonEntranceInfo.journalInstanceID
				entranceInfo.atlasName = dungeonEntranceInfo.atlasName
				
				local pin = self:GetMap():AcquirePin("IPAInstancePortalPinTemplate", entranceInfo);
				pin.dataProvider = self;
				pin:SetSuperTracked(false)

				if C_SuperTrack.IsSuperTrackingMapPin() then
					local areaPoiID = pin.poiInfo.areaPoiID or 0;
					local superTrackedMapPinType, superTrackedMapPinTypeID = C_SuperTrack.GetSuperTrackedMapPin()
					if (superTrackedMapPinType == Enum.SuperTrackingMapPinType.AreaPOI) and (areaPoiID == superTrackedMapPinTypeID) then
						pin:SetSuperTracked(true)
					end
				end
			end
		end
		
	end

	-- IPA databse
	if IPAUIPinDB[uiMapID] then
		local count = #IPAUIPinDB[uiMapID]
		local isContinent = false;
		for i = 1, #IPAUIContinentMapDB do
			if IPAUIContinentMapDB[i] == uiMapID then
				isContinent = true;
			end
		end

        if not (isContinent) then
            return
        end

		IPAUIPrintDebug("Map is continent = "..(isContinent and 'true' or 'false'))
		local playerFaction = UnitFactionGroup("player")

		for i = 1, count do
			local entranceInfo = IPAUIGetEntranceInfoForMapID(uiMapID, i);

			if entranceInfo then
				local factionWhitelist = entranceInfo["factionWhitelist"];

				local isWhitelisted = true;

				if factionWhitelist and not (factionWhitelist == playerFaction) then
					isWhitelisted = false
				end

				if showDungeonEntrancesOnMap then
					if (isWhitelisted) then
						local pin = self:GetMap():AcquirePin("IPAInstancePortalPinTemplate", entranceInfo);
						pin.dataProvider = self;
						pin:SetSuperTracked(false)

						if C_SuperTrack.IsSuperTrackingMapPin() then
							local areaPoiID = pin.poiInfo.areaPoiID or 0;
							local superTrackedMapPinType, superTrackedMapPinTypeID = C_SuperTrack.GetSuperTrackedMapPin()
							if (superTrackedMapPinType == Enum.SuperTrackingMapPinType.AreaPOI) and (areaPoiID == superTrackedMapPinTypeID) then
								pin:SetSuperTracked(true)
							end
						end
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
end

function IPAInstancePortalProviderPinMixin:OnMouseClickAction(button)
	if (not button) then return end

	local useWaypointsContient = IPASettings and IPASettings.options.useWaypointsContient
	useWaypointsContient = useWaypointsContient == nil and true or useWaypointsContient

	local useTomTomContinent = IPASettings and IPASettings.options.useTomTomContinent
	useTomTomContinent = useTomTomContinent == nil and false or useTomTomContinent
	useTomTomContinent = useTomTomContinent and (TomTom ~= nil) or false
	IPAUIPrintDebug("useTomTomContinent: "..tostring(useTomTomContinent))

	if (button == "LeftButton") and (useWaypointsContient == true) then

		local wp_mapid, wp_x, wp_y, wp_name
		IPAUIPrintDebug("IPAInstancePortalProviderPinMixin:OnMouseClickAction, button: "..tostring(button))
		IPAUIPrintDebug("IPAInstancePortalProviderPinMixin:OnMouseClickAction, self.hub: "..tostring(self.hub))

		local uiMapID = self:GetMap():GetMapID();
		IPAUIPrintDebug("uiMapID: "..uiMapID)
		if not uiMapID then return end

		if self.hub == 0 then

			local journalInstanceID = self.journalInstanceID
			IPAUIPrintDebug("self.journalInstanceID: "..journalInstanceID)
			if not journalInstanceID then return end

			-- function C_Map.GetMapChildrenInfo(uiMapID, optional mapType, optional allDescendants)
			local mapChildren = C_Map.GetMapChildrenInfo(uiMapID, Enum.UIMapType.Zone) -- get current map children
			if ( (type(mapChildren) ~= 'table') or (#mapChildren < 1) ) then return end -- mapChildren is not table or empty

			--[[
			if (journalInstanceID == 1179) then -- special case "The Eternal Palace"
				local name = EJ_GetInstanceInfo(1179) or "The Eternal Palace"
				--wp_mapid = 1355
				--wp_x = (0.50369811058044)
				--wp_y = (0.12483072280884)
				wp_name = name
			else
			]]
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
							if (not self.areaPOIID) then self.areaPOIID = dungeonEntranceInfo.areaPoiID or 0 end
							IPAUIPrintDebug("childMapInfo.mapID: "..childMapInfo.mapID)
							IPAUIPrintDebug("dungeonEntranceInfo.name: "..dungeonEntranceInfo.name)
							IPAUIPrintDebug("dungeonEntranceInfo.position.x: "..dungeonEntranceInfo.position.x)
							IPAUIPrintDebug("dungeonEntranceInfo.position.y: "..dungeonEntranceInfo.position.y)
						end
					end
				end
			end

			-- if anything is missing, TRY to use Pin itself as Source
			if not (wp_mapid and wp_x and wp_y and wp_name) then
				IPAUIPrintDebug("Waypoint Info is missing, try to use PIN as Source")
				for k, v in pairs({wp_mapid="wp_mapid", wp_x="wp_x", wp_y="wp_y", wp_name="wp_name"}) do
						if not k then IPAUIPrintDebug("Missing: " .. v) end
				end

				wp_mapid = self:GetMap():GetMapID()
				wp_x, wp_y = self:GetPosition()
				wp_name = self.name or "Waypoint"
		end

		else -- if self.hub ~= 0
			wp_mapid = self:GetMap():GetMapID();
			wp_x, wp_y = self:GetPosition()
			wp_name = self.name or "Waypoint"
		end

		IPAUIPrintDebug("\nWaypoint Info:\n  MapID: "..wp_mapid.."\n  X: "..wp_x.."\n  Y: "..wp_y.."\n  Name: "..wp_name.."\n  System: "..(useTomTom and "TomTom" or "Blizzard").."\n")

		if useTomTomContinent ~= true then
			local _, areaPoiID = self:GetSuperTrackData()
			if areaPoiID and areaPoiID > 0 then
				if self:IsSuperTracked() then
					C_SuperTrack.ClearAllSuperTracked();
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
				else
					PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON);
					C_SuperTrack.SetSuperTrackedMapPin(self:GetSuperTrackData())
				end
			else
				AddNativeWaypoint(wp_mapid, wp_x, wp_y)
			end
		else
			AddTomTomWaypoint(wp_mapid, wp_x, wp_y, wp_name)
		end

	elseif (button == "RightButton") then
		IPAUIPrintDebug("journalInstanceID: "..tostring(self.journalInstanceID))
		EncounterJournal_LoadUI();
		EncounterJournal_OpenJournal(nil, self.journalInstanceID);
	end

end


-- Waypoint Function for Blizzard Dungeon Entrance Pins
local function WaypointDungeonEntrancePinMixin(self, button)
	if (not self) or (not button) then return end

	local useWaypointsZone = IPASettings and IPASettings.options.useWaypointsZone
	useWaypointsZone = useWaypointsZone == nil and true or useWaypointsZone

	local useTomTomZone = IPASettings and IPASettings.options.useTomTomZone
	useTomTomZone = useTomTomZone == nil and false or useTomTomZone
	useTomTomZone = useTomTomZone and (TomTom ~= nil) or false
	IPAUIPrintDebug("useTomTomZone: "..tostring(useTomTomZone))

	if (button == "LeftButton") and (useWaypointsZone == true) then
		if (useTomTomZone == true) then
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
			-- useTomTomZone is NOT true, use Native Tracking system
			SuperTrackablePinMixin.OnMouseClickAction(self, button);
		end
	elseif button == "RightButton" then
		IPAUIPrintDebug("journalInstanceID: "..tostring(self.journalInstanceID))
		EncounterJournal_LoadUI();
		EncounterJournal_OpenJournal(nil, self.journalInstanceID);
	end
end
_G.DungeonEntrancePinMixin.OnMouseClickAction = WaypointDungeonEntrancePinMixin