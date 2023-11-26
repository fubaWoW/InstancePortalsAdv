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
						self:GetMap():AcquirePin("IPAInstancePortalPinTemplate", entranceInfo);
					end
				end
			end
		end
	end

end

-- local function for "Add Waypoints" with the feature to "force" Built-In Waypoint System, just set "useTomTom" to false or leave it blank
local function AddWaypoint(mapID, x, y, title, useTomTom)
  if (useTomTom == true) and TomTom then
    title = title or "Waypoint"
    TomTom:AddWaypoint(mapID, x, y, {
      title = title,
      persistent = false,
      minimap = true,
      world = true,
      from = addonName or "InstancePortalsAdvanced"
    })
  else -- if TomTom is not installed or useTomTom is false you the Built-In Waypoint System
    if C_Map.CanSetUserWaypointOnMap(mapID) then
      local vector = CreateVector2D(x, y)
      local mapPoint = UiMapPoint.CreateFromVector2D(mapID, vector)
      C_Map.SetUserWaypoint(mapPoint)
      C_SuperTrack.SetSuperTrackedUserWaypoint(true)
			PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON);
    end
  end
end


--[[ Pin ]]--
IPAInstancePortalProviderPinMixin = BaseMapPoiPinMixin:CreateSubPin("PIN_FRAME_LEVEL_DUNGEON_ENTRANCE");

function IPAInstancePortalProviderPinMixin:OnAcquired(dungeonEntranceInfo) -- override
	BaseMapPoiPinMixin.OnAcquired(self, dungeonEntranceInfo);

	self.hub = dungeonEntranceInfo.hub
	self.tier = dungeonEntranceInfo.tier;
	self.journalInstanceID = dungeonEntranceInfo.journalInstanceID;
end

function IPAInstancePortalProviderPinMixin:OnClick(button)
	if (not button) then return end

	local useWaypoints = true
	local useTomTom = true
	if IPASettings and IPASettings.options then
		useWaypoints = IPASettings.options.useWaypoints
		useTomTom = IPASettings.options.useTomTom and (TomTom ~= nil) or false
	end

  local wp_mapid, wp_x, wp_y, wp_name
	IPAUIPrintDebug("IPAInstancePortalProviderPinMixin:OnClick, button: "..button)
	IPAUIPrintDebug("IPAInstancePortalProviderPinMixin:OnClick, self.hub: "..self.hub)

  if self.hub == 0 then
    if (button == "LeftButton" and IsShiftKeyDown() and useWaypoints == true) then
      local uiMapID = self:GetMap():GetMapID();
			if Debug and Debug == true then print("uiMapID: "..uiMapID) end
      if not uiMapID then return end
      local mapChildren = C_Map.GetMapChildrenInfo(uiMapID, Enum.UIMapType.Zone) -- get current map children
      if ( (type(mapChildren) ~= 'table') or (#mapChildren < 1) ) then return end -- mapChildren is not table or empty
      local journalInstanceID = self.journalInstanceID
			if Debug and Debug == true then print("journalInstanceID: "..journalInstanceID) end
      if not journalInstanceID then return end

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


			-- if anything is missing, TRY to use Pin itself as Source
      if (not wp_mapid) or (not dungeonEntranceInfo) or (not dungeonEntranceInfo.position) or (not dungeonEntranceInfo.position.x) or (not dungeonEntranceInfo.position.y) then
        wp_mapid = self:GetMap():GetMapID();
        wp_x, wp_y = self:GetPosition()
        wp_name = self.name or "Waypoint"
      end
    else -- not ""LeftButton" and IsShiftKeyDown()" or "useWaypoints == false" then open Encounter Journal
			if ( not EncounterJournal ) then
				EncounterJournal_LoadUI();
			end
			EncounterJournal_OpenJournal(nil, self.journalInstanceID)
			_G.EncounterJournal:SetScript("OnShow", nil)
    end
  else -- if self.hub ~= 0, try to use Map Pin itself as Source
    if (button == "LeftButton" and IsShiftKeyDown() and useWaypoints == true) then
      wp_mapid = self:GetMap():GetMapID();
      wp_x, wp_y = self:GetPosition()
      wp_name = self.name or "Waypoint"
    end
  end

	-- check for all needed Variables and Add Waypoint if all Variables are present
  if (button == "LeftButton" and IsShiftKeyDown() and useWaypoints == true) and wp_mapid and wp_x and wp_y and wp_name then
    AddWaypoint(wp_mapid, wp_x, wp_y, wp_name, useTomTom)
  end
end

-- Waypoint Function for Blizzard Dungeon Entrance Pins
local function WaypointDungeonEntrancePinMixin(self, button)
	if (not self) or (not button) then return end

	local useWaypoints = true
	local useTomTom = true
	if IPASettings and IPASettings.options then
		useWaypoints = IPASettings.options.useWaypoints
		useTomTom = IPASettings.options.useTomTom and (TomTom ~= nil) or false
	end

	local wp_mapid, wp_x, wp_y, wp_name
	if (button == "LeftButton" and IsShiftKeyDown() and useWaypoints == true) then
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
		if (not wp_mapid) or (not dungeonEntranceInfo) or (not dungeonEntranceInfo.position) or (not dungeonEntranceInfo.position.x) or (not dungeonEntranceInfo.position.y) then
			wp_mapid = self:GetMap():GetMapID();
			wp_x, wp_y = self:GetPosition()
			wp_name = self.name or "Waypoint"
		end
	else -- not ""LeftButton" and IsShiftKeyDown()" or "useWaypoints == false" then open Encounter Journal
		if ( not EncounterJournal ) then
			EncounterJournal_LoadUI();
		end
		EncounterJournal_OpenJournal(nil, self.journalInstanceID)
	 _G.EncounterJournal:SetScript("OnShow", nil)
		
	end

	if (button == "LeftButton" and IsShiftKeyDown() and useWaypoints == true) and wp_mapid and wp_x and wp_y and wp_name then
		AddWaypoint(wp_mapid, wp_x, wp_y, wp_name, useTomTom)
	end
end
_G.DungeonEntrancePinMixin.OnMouseClickAction = WaypointDungeonEntrancePinMixin