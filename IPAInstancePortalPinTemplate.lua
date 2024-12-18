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
	self:RemoveAllData()

	-- Check if dungeon entrances should be shown and if continent map pins are enabled
	if not (C_CVar and C_CVar.GetCVarBool("showDungeonEntrancesOnMap")) then return end
	if not (IPASettings and IPASettings.options.pinsOnContinentMap) then return end

	local uiMapID = self:GetMap():GetMapID()
	local mapInfo = C_Map.GetMapInfo(uiMapID)
	if not (uiMapID and mapInfo and mapInfo.mapType == Enum.UIMapType.Continent) then return end

	local mapChildren = C_Map.GetMapChildrenInfo(uiMapID, Enum.UIMapType.Zone)
	if not (type(mapChildren) == 'table' and #mapChildren > 0) then return end

	-- Function to create and add pins
	local function CreatePin(info, waypoint)
		local pin = self:GetMap():AcquirePin("IPAInstancePortalPinTemplate", info)
		pin.dataProvider = self
		pin:SetSuperTracked(false)

		if waypoint then
			pin.waypoint = CreateVector2D(waypoint.wpx, waypoint.wpy)
			pin.waypoint.zone = waypoint.wpzone
			pin.waypoint.name = waypoint.wpname
		end

		if C_SuperTrack.IsSuperTrackingMapPin() then
			local areaPoiID = pin.poiInfo.areaPoiID or 0
			local superTrackedMapPinType, superTrackedMapPinTypeID = C_SuperTrack.GetSuperTrackedMapPin()
			if superTrackedMapPinType == Enum.SuperTrackingMapPinType.AreaPOI and areaPoiID == superTrackedMapPinTypeID then
				pin:SetSuperTracked(true)
			end
		end
	end

	-- Process dungeon entrances for child maps
	for _, childMapInfo in ipairs(mapChildren) do
		for _, entrance in ipairs(C_EncounterJournal.GetDungeonEntrancesForMap(childMapInfo.mapID)) do
			local override = false
			if IPAUISpecialPinDB and IPAUISpecialPinDB[uiMapID] then
				for _, specialPin in ipairs(IPAUISpecialPinDB[uiMapID]) do
					if specialPin.journalInstanceID == entrance.journalInstanceID then
						override = true
						break
					end
				end
			end

			if not override then
				local pos_vector = CreateVector2D(entrance.position.x, entrance.position.y)
				local _, worldPosition = C_Map.GetWorldPosFromMapPos(childMapInfo.mapID, pos_vector)
				local _, mapPosition = C_Map.GetMapPosFromWorldPos(_, worldPosition)
				local entranceInfo = {
					position = CreateVector2D(mapPosition.x, mapPosition.y),
					areaPoiID = entrance.areaPoiID,
					name = entrance.name,
					description = entrance.description,
					journalInstanceID = entrance.journalInstanceID,
					atlasName = entrance.atlasName
				}
				
				CreatePin(entranceInfo)
			end
		end
	end

	-- Process special pins
	local specialPinsForMap = IPAUISpecialPinDB[uiMapID]
	if specialPinsForMap then
		for _, specialPinData in ipairs(specialPinsForMap) do
			local entranceInfo = {
				position = CreateVector2D(specialPinData.x, specialPinData.y),
				areaPoiID = 0,
				journalInstanceID = specialPinData.journalInstanceID,
				atlasName = specialPinData.atlasName or "Dungeon",
				description = specialPinData.atlasName == "Raid" and LFG_TYPE_RAID or LFG_TYPE_DUNGEON,
				name = EJ_GetInstanceInfo(specialPinData.journalInstanceID) or "Waypoint"
			}

			if specialPinData.instanceZone and type(specialPinData.instanceZone) == "number" then
				for _, entrance in ipairs(C_EncounterJournal.GetDungeonEntrancesForMap(specialPinData.instanceZone)) do
					if entrance.journalInstanceID == specialPinData.journalInstanceID then
						entranceInfo = {
							position = entranceInfo.position,
							areaPoiID = entrance.areaPoiID,
							name = entrance.name,
							description = entrance.description,
							journalInstanceID = entrance.journalInstanceID,
							atlasName = entrance.atlasName
						}
					end
				end
			end

			CreatePin(entranceInfo, specialPinData)
		end
	end
end

-- local function for "Add Waypoints" with the feature to "force" Built-In Waypoint System, just set "useTomTom" to false or leave it blank
local function AddNativeWaypoint(mapID, x, y)
	if C_Map.CanSetUserWaypointOnMap(mapID) then
		C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
		C_SuperTrack.SetSuperTrackedUserWaypoint(true)
		PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON)
	end
end

local function AddTomTomWaypoint(mapID, x, y, title)
	if TomTom then
		TomTom:AddWaypoint(mapID, x, y, {
			title = title or "Waypoint",
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
	if not button then return end

	local useWaypointsContinent = IPASettings and (IPASettings.options.useWaypointsContinent ~= false)
	local useTomTomContinent = IPASettings and (IPASettings.options.useTomTomContinent == true) and (TomTom ~= nil)
	IPA:DebugPrint("useTomTomContinent: " .. tostring(useTomTomContinent))
	IPA:DebugPrint("OnMouseClickAction, button: " .. tostring(button))

	if button == "LeftButton" and useWaypointsContinent then
		local _, areaPoiID = self:GetSuperTrackData()
		if areaPoiID and areaPoiID > 0 and not useTomTomContinent then
			if self:IsSuperTracked() then
				C_SuperTrack.ClearAllSuperTracked()
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
			else
				PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
				C_SuperTrack.SetSuperTrackedMapPin(self:GetSuperTrackData())
			end
		else
			local wp_mapid, wp_x, wp_y, wp_name
			local uiMapID = self:GetMap():GetMapID()
			if not uiMapID then return end

			local journalInstanceID = self.journalInstanceID or self.poiInfo.journalInstanceID
			if not journalInstanceID then return end

			-- Find matching dungeon entrance
			for _, childMapInfo in ipairs(C_Map.GetMapChildrenInfo(uiMapID, Enum.UIMapType.Zone) or {}) do
				for _, dungeonEntranceInfo in ipairs(C_EncounterJournal.GetDungeonEntrancesForMap(childMapInfo.mapID)) do
					if dungeonEntranceInfo.journalInstanceID == journalInstanceID then
						wp_mapid = childMapInfo.mapID
						wp_x = dungeonEntranceInfo.position.x
						wp_y = dungeonEntranceInfo.position.y
						wp_name = dungeonEntranceInfo.name or "Waypoint"
						self.areaPOIID = self.areaPOIID or dungeonEntranceInfo.areaPoiID or 0
					end
				end
			end

			-- Use existing waypoint or pin as fallback
			wp_mapid = wp_mapid or (self.waypoint and self.waypoint.zone) or uiMapID
			wp_x = wp_x or (self.waypoint and self.waypoint.x) or self:GetPosition()
			wp_y = wp_y or (self.waypoint and self.waypoint.y) or select(2, self:GetPosition())
			wp_name = wp_name or (self.waypoint and self.waypoint.name) or EJ_GetInstanceInfo(journalInstanceID) or self.name or "Waypoint"

			if useTomTomContinent then
				AddTomTomWaypoint(wp_mapid, wp_x, wp_y, wp_name)
			else
				AddNativeWaypoint(wp_mapid, wp_x, wp_y)
			end
		end

	elseif button == "RightButton" then
		local journalInstanceID = self.journalInstanceID or self.poiInfo.journalInstanceID
		--print("journalInstanceID: " .. tostring(self.journalInstanceID))
		IPA:DebugPrint("journalInstanceID: " .. tostring(journalInstanceID))
		EncounterJournal_LoadUI()
		EncounterJournal_OpenJournal(nil, journalInstanceID)
	end
end


-- Waypoint Function for Blizzard Dungeon Entrance Pins
local function WaypointDungeonEntrancePinMixin(self, button)
	if not (self and button) then return end

	local useWaypointsZone = IPASettings and (IPASettings.options.useWaypointsZone ~= false)
	local useTomTomZone = IPASettings and (IPASettings.options.useTomTomZone == true) and (TomTom ~= nil)
	IPA:DebugPrint("useTomTomZone: " .. tostring(useTomTomZone))

	if button == "LeftButton" and useWaypointsZone then
		if useTomTomZone then
			local wp_mapid, wp_x, wp_y, wp_name
			local uiMapID = self:GetMap():GetMapID()
			local journalInstanceID = self.journalInstanceID
			IPA:DebugPrint("journalInstanceID: " .. tostring(journalInstanceID))

			-- Get the dungeon entrance info for the current map
			for _, dungeonEntranceInfo in ipairs(C_EncounterJournal.GetDungeonEntrancesForMap(uiMapID)) do
				if dungeonEntranceInfo.journalInstanceID == journalInstanceID then
					wp_mapid = uiMapID
					wp_x = dungeonEntranceInfo.position.x
					wp_y = dungeonEntranceInfo.position.y
					wp_name = dungeonEntranceInfo.name or "Waypoint"
				end
			end

			-- Fallback to pin's position if necessary
			if not (wp_mapid and wp_x and wp_y and wp_name) then
				IPA:DebugPrint("Waypoint Info is missing, using Pin as Source")
				wp_mapid = uiMapID
				wp_x, wp_y = self:GetPosition()
				wp_name = self.name or "Waypoint"
			end

			AddTomTomWaypoint(wp_mapid, wp_x, wp_y, wp_name)
		else
			-- Use native tracking system
			SuperTrackablePinMixin.OnMouseClickAction(self, button)
		end

	elseif button == "RightButton" then
		IPA:DebugPrint("journalInstanceID: " .. tostring(self.journalInstanceID))
		EncounterJournal_LoadUI()
		EncounterJournal_OpenJournal(nil, self.journalInstanceID)
	end
end
_G.DungeonEntrancePinMixin.OnMouseClickAction = WaypointDungeonEntrancePinMixin