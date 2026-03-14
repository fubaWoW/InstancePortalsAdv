local addonName, IPA = ...

local refreshTimer

IPAInstancePortalMapDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)

function IPAInstancePortalMapDataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate("IPAInstancePortalPinTemplate")
end

function IPAInstancePortalMapDataProviderMixin:OnShow()
	self:RegisterEvent("CVAR_UPDATE")
end

function IPAInstancePortalMapDataProviderMixin:OnHide()
	self:UnregisterEvent("CVAR_UPDATE")
end

function IPAInstancePortalMapDataProviderMixin:OnEvent(event, ...)
	if event == "CVAR_UPDATE" then
		local eventName, value = ...;
		if eventName == "showDungeonEntrancesOnMap" then
			self:RefreshAllData()
		end
	end
end

local function DoRefresh(self)
	self:RemoveAllData()

	local map = self:GetMap()
    local uiMapID = map and map:GetMapID()
    if not uiMapID then return end
	
	if IPA.mapBlacklist_Dungeon and IPA.mapBlacklist_Dungeon[uiMapID] then return end

    if not (C_CVar and C_CVar.GetCVarBool("showDungeonEntrancesOnMap")) then return end

	local showPins = IPASettings and IPASettings.options and IPASettings.options.showOwnPins or false
    if not showPins then return end

    local mapInfo = C_Map.GetMapInfo(uiMapID)

	local isContinent = mapInfo.mapType == Enum.UIMapType.Continent
	local isZone = mapInfo.mapType == Enum.UIMapType.Zone
	if not (isContinent or isZone) then return end

    local mapChildren = C_Map.GetMapChildrenInfo(uiMapID, Enum.UIMapType.Zone) or {}
	local specialPinsForMap = IPA.specialPin_Dungeon and IPA.specialPin_Dungeon[uiMapID]
	if #mapChildren == 0 and not specialPinsForMap then return end

	-- Function to create and add pins
	local function CreatePin(info, waypoint)
		local pin = self:GetMap():AcquirePin("IPAInstancePortalPinTemplate", info)
		pin.dataProvider = self
		pin:SetSuperTracked(false)

		pin.journalInstanceID = info and info.journalInstanceID or 0
		pin.description = info and info.description or ""
		pin.isRaid = info and info.atlasName == "Raid" or false

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

	-- Process dungeon entrances for child maps (Continent only!)
	if isContinent and #mapChildren > 0 then
		local processedIDs = {}  -- track already created pins

		for _, childMapInfo in ipairs(mapChildren) do
			local mapID = childMapInfo.mapID
			local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(mapID)
			for _, entrance in ipairs(dungeonEntrances) do
				-- Skip if already processed

				if not processedIDs[entrance.journalInstanceID] then
					processedIDs[entrance.journalInstanceID] = true

					local override = false

					if specialPinsForMap then
						for _, specialPin in ipairs(specialPinsForMap) do
							if specialPin.journalInstanceID == entrance.journalInstanceID then
								override = true
								break
							end
						end
					end

					if not override then
						local pos_vector = CreateVector2D(entrance.position.x, entrance.position.y)
						local continentID, worldPosition = C_Map.GetWorldPosFromMapPos(childMapInfo.mapID, pos_vector)
						local _, mapPosition = C_Map.GetMapPosFromWorldPos(continentID, worldPosition, uiMapID)
						if mapPosition then
							local finalDesc = entrance.description
							if not finalDesc or finalDesc == "" then
								finalDesc = (entrance.atlasName == "Raid") and _G.LFG_TYPE_RAID or _G.LFG_TYPE_DUNGEON
							end

							local entranceInfo = {
								position = CreateVector2D(mapPosition.x, mapPosition.y),
								areaPoiID = entrance.areaPoiID,
								name = entrance.name,
								description = finalDesc,
								journalInstanceID = entrance.journalInstanceID,
								atlasName = entrance.atlasName,
								isSpecialPin = false
							}
							CreatePin(entranceInfo)
						end
					end
				end
			end
		end
	end

	-- Process special pins
	if specialPinsForMap then
		for _, specialPinData in ipairs(specialPinsForMap) do
			local entranceInfo = {
				position = CreateVector2D(specialPinData.x, specialPinData.y),
				areaPoiID = 0,
				journalInstanceID = specialPinData.journalInstanceID,
				atlasName = specialPinData.atlasName or "Dungeon",
				description = specialPinData.atlasName == "Raid" and _G.LFG_TYPE_RAID or _G.LFG_TYPE_DUNGEON,
				name = EJ_GetInstanceInfo(specialPinData.journalInstanceID) or "Waypoint"
			}

			if specialPinData.instanceZone and type(specialPinData.instanceZone) == "number" then
				for _, entrance in ipairs(C_EncounterJournal.GetDungeonEntrancesForMap(specialPinData.instanceZone)) do
					if entrance.journalInstanceID == specialPinData.journalInstanceID then
						local finalDesc = entrance.description
						if not finalDesc or finalDesc == "" then
							finalDesc = (entrance.atlasName == "Raid") and _G.LFG_TYPE_RAID or _G.LFG_TYPE_DUNGEON
						end

						entranceInfo = {
							position = entranceInfo.position,
							areaPoiID = entrance.areaPoiID,
							name = entrance.name,
							description = finalDesc,
							journalInstanceID = entrance.journalInstanceID,
							atlasName = entrance.atlasName,
							isSpecialPin = true
						}
					end
				end
			end

			CreatePin(entranceInfo, specialPinData)
		end
	end
end

function IPAInstancePortalMapDataProviderMixin:RefreshAllData(fromOnShow)
	-- prevent bouncing
    if refreshTimer then refreshTimer:Cancel() end
    refreshTimer = C_Timer.NewTimer(0, function()
        refreshTimer = nil
        xpcall(function() DoRefresh(self) end, geterrorhandler())
    end)
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

-- Pin definition
IPAInstancePortalProviderPinMixin = BaseMapPoiPinMixin:CreateSubPin("PIN_FRAME_LEVEL_DUNGEON_ENTRANCE")

-- Pin Taint fixes
function IPAInstancePortalProviderPinMixin:SetPassThroughButtons() end
function IPAInstancePortalProviderPinMixin:UpdateMousePropagation() end
function IPAInstancePortalProviderPinMixin:DoesMapTypeAllowSuperTrack() return true end

function IPAInstancePortalProviderPinMixin:OnAcquired(dungeonEntranceInfo) -- override
	BaseMapPoiPinMixin.OnAcquired(self, dungeonEntranceInfo)
end

-- secure EncounterJournal_OpenJournal and prevent open in combat
local function SecureOpenEncounterJournal(journalInstanceID)

    if InCombatLockdown() then
        UIErrorsFrame:AddMessage("Cannot open Encounter Journal during combat.", 1, 0.2, 0.2)
        return
    end

    C_Timer.After(0.01, function()
		if not EncounterJournal then
            EncounterJournal_LoadUI()
        end

		EncounterJournal_OpenJournal(nil, journalInstanceID)
    end)

end

function IPAInstancePortalProviderPinMixin:OnMouseClickAction(button)
	if not button then return end

	local useTomTom = IPASettings and (IPASettings.options.useTomTom == true) and (TomTom ~= nil)

	if button == "LeftButton" then
		local _, areaPoiID = self:GetSuperTrackData()
		if areaPoiID and (areaPoiID > 0) and (not useTomTom) then
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

			if useTomTom then
				AddTomTomWaypoint(wp_mapid, wp_x, wp_y, wp_name)
			else
				AddNativeWaypoint(wp_mapid, wp_x, wp_y)
			end
		end

	elseif button == "RightButton" then
		local journalInstanceID = self.journalInstanceID or self.poiInfo.journalInstanceID
		IPA:DebugPrint("journalInstanceID: " .. tostring(journalInstanceID))

		SecureOpenEncounterJournal(journalInstanceID)
	end
end


-- new method to hook map pins and hopefully is taint secure now!
local function PatchDungeonEntrancePins()

    if not WorldMapFrame or not WorldMapFrame:IsShown() then
        return
    end

    for pin in WorldMapFrame:EnumeratePinsByTemplate("DungeonEntrancePinTemplate") do

        if not pin.IPA_CustomClick then
            pin.IPA_CustomClick = true

            pin.OnMouseClickAction = function(self, button)

                local useTomTom = IPASettings and (IPASettings.options.useTomTom == true) and (TomTom ~= nil)

                if button == "LeftButton" then

                    if useTomTom then

                        local wp_mapid, wp_x, wp_y, wp_name
                        local uiMapID = self:GetMap():GetMapID()
                        local journalInstanceID = self.journalInstanceID

                        for _, dungeonEntranceInfo in ipairs(C_EncounterJournal.GetDungeonEntrancesForMap(uiMapID)) do
                            if dungeonEntranceInfo.journalInstanceID == journalInstanceID then
                                wp_mapid = uiMapID
                                wp_x = dungeonEntranceInfo.position.x
                                wp_y = dungeonEntranceInfo.position.y
                                wp_name = dungeonEntranceInfo.name or "Waypoint"
                                break
                            end
                        end

                        if not (wp_mapid and wp_x and wp_y and wp_name) then
                            wp_mapid = uiMapID
                            wp_x, wp_y = self:GetPosition()
                            wp_name = self.name or "Waypoint"
                        end

                        AddTomTomWaypoint(wp_mapid, wp_x, wp_y, wp_name)

                    else
                        SuperTrackablePinMixin.OnMouseClickAction(self, button)
                    end

                elseif button == "RightButton" then
                    SecureOpenEncounterJournal(self.journalInstanceID)
                end

            end

        end

    end

end

hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
    C_Timer.After(0, PatchDungeonEntrancePins)
end)

WorldMapFrame:HookScript("OnShow", function()
    C_Timer.After(0, PatchDungeonEntrancePins)
end)