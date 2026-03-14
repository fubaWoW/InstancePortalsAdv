local addonName, IPA = ...

local delveRefreshTimer

IPADelveMapDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)

function IPADelveMapDataProviderMixin:RemoveAllData()
    self:GetMap():RemoveAllPinsByTemplate("IPADelveEntrancePinTemplate")
end

function IPADelveMapDataProviderMixin:OnShow()
    self:RegisterEvent("CVAR_UPDATE")
end

function IPADelveMapDataProviderMixin:OnHide()
    self:UnregisterEvent("CVAR_UPDATE")
end

function IPADelveMapDataProviderMixin:OnEvent(event, ...)
    if event == "CVAR_UPDATE" then
        local eventName, value = ...
        if eventName == "showDelveEntrancesOnMap" then
            self:RefreshAllData()
        end
    end
end

local function DoDelveRefresh(self)
	self:RemoveAllData()

    local map = self:GetMap()
    local uiMapID = map and map:GetMapID()
    if not uiMapID then return end
	
	if IPA.mapBlacklist_Delve and IPA.mapBlacklist_Delve[uiMapID] then return end
	
    if not (C_CVar and C_CVar.GetCVarBool("showDelveEntrancesOnMap")) then return end

    local showPins = IPASettings and IPASettings.options and IPASettings.options.showOwnDelvePins or false
    if not showPins then return end

    local mapInfo = C_Map.GetMapInfo(uiMapID)
    if not mapInfo then return end

    local isContinent = mapInfo.mapType == Enum.UIMapType.Continent
    local isZone = mapInfo.mapType == Enum.UIMapType.Zone
    if not (isContinent or isZone) then return end

    local mapChildren = C_Map.GetMapChildrenInfo(uiMapID, Enum.UIMapType.Zone) or {}
    local specialPinsForMap = IPA.specialPin_Delve and IPA.specialPin_Delve[uiMapID]
    if #mapChildren == 0 and not specialPinsForMap then return end

    -- Function to create and add pins
    local function CreatePin(info, waypoint)
        local pin = self:GetMap():AcquirePin("IPADelveEntrancePinTemplate", info)
        pin.dataProvider = self
        pin:SetSuperTracked(false)

        if waypoint then
            pin.waypoint = CreateVector2D(waypoint.wpx, waypoint.wpy)
            pin.waypoint.zone = waypoint.wpzone
            pin.waypoint.name = waypoint.wpname
        end

        if C_SuperTrack.IsSuperTrackingMapPin() then
            local areaPoiID = pin.poiInfo and pin.poiInfo.areaPoiID or 0
            local superTrackedMapPinType, superTrackedMapPinTypeID = C_SuperTrack.GetSuperTrackedMapPin()
            if superTrackedMapPinType == Enum.SuperTrackingMapPinType.AreaPOI and areaPoiID == superTrackedMapPinTypeID then
                pin:SetSuperTracked(true)
            end
        end
    end

    -- Process delve entrances for child maps (Continent only!)
    if isContinent and #mapChildren > 0 then
        local processedIDs = {}

        for _, childMapInfo in ipairs(mapChildren) do
            local mapID = childMapInfo.mapID
            local delveAreaPOIs = C_AreaPoiInfo.GetDelvesForMap(mapID) or {}

            for _, areaPoiID in ipairs(delveAreaPOIs) do
                if not processedIDs[areaPoiID] then
                    processedIDs[areaPoiID] = true

                    local override = false
                    if specialPinsForMap then
                        for _, specialPin in ipairs(specialPinsForMap) do
                            if specialPin.areaPoiID == areaPoiID then
                                override = true
                                break
                            end
                        end
                    end

                    if not override then
						local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapID, areaPoiID)
						if poiInfo then
							local pos_vector = CreateVector2D(poiInfo.position:GetXY())
							local continentID, worldPosition = C_Map.GetWorldPosFromMapPos(mapID, pos_vector)
							local _, mapPosition = C_Map.GetMapPosFromWorldPos(continentID, worldPosition, uiMapID)
							if mapPosition then
								-- Create a COPY, never modify original poiInfo!
								local poiInfoCopy = CopyTable(poiInfo)
								poiInfoCopy.position = CreateVector2D(mapPosition.x, mapPosition.y)
								poiInfoCopy.dataProvider = self
								CreatePin(poiInfoCopy)
							end
						end
					end
                end
            end
        end
    end

    -- Process special pins
    if specialPinsForMap then
        for _, specialPinData in ipairs(specialPinsForMap) do
            local poiInfo = specialPinData.areaPoiID and specialPinData.instanceZone and
                C_AreaPoiInfo.GetAreaPOIInfo(specialPinData.instanceZone, specialPinData.areaPoiID)

            if poiInfo then
				local poiInfoCopy = CopyTable(poiInfo)
				poiInfoCopy.position = CreateVector2D(specialPinData.x, specialPinData.y)
				poiInfoCopy.dataProvider = self
				CreatePin(poiInfoCopy, specialPinData)
			end
        end
    end
end

function IPADelveMapDataProviderMixin:RefreshAllData(fromOnShow)
    if delveRefreshTimer then delveRefreshTimer:Cancel() end
    delveRefreshTimer = C_Timer.NewTimer(0, function()
        delveRefreshTimer = nil
        xpcall(function() DoDelveRefresh(self) end, geterrorhandler())
    end)
end

-- Add Waypoints
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
IPADelveProviderPinMixin = BaseMapPoiPinMixin:CreateSubPin("PIN_FRAME_LEVEL_DELVE_ENTRANCE")

-- Taint fixes
function IPADelveProviderPinMixin:SetPassThroughButtons() end
function IPADelveProviderPinMixin:UpdateMousePropagation() end
function IPADelveProviderPinMixin:DoesMapTypeAllowSuperTrack() return true end
function IPADelveProviderPinMixin:GetSuperTrackMarkerOffset() return -7, 7 end

function IPADelveProviderPinMixin:OnAcquired(poiInfo)
    BaseMapPoiPinMixin.OnAcquired(self, poiInfo)
end

function IPADelveProviderPinMixin:OnMouseClickAction(button)
    if not button then return end

    local useTomTom = IPASettings and (IPASettings.options.useTomTomDelve == true) and (TomTom ~= nil)

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

            local areaPoiID = self.poiInfo and self.poiInfo.areaPoiID

            -- Find matching delve entrance in child maps
            for _, childMapInfo in ipairs(C_Map.GetMapChildrenInfo(uiMapID, Enum.UIMapType.Zone) or {}) do
                for _, poiID in ipairs(C_AreaPoiInfo.GetDelvesForMap(childMapInfo.mapID) or {}) do
                    if poiID == areaPoiID then
                        local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(childMapInfo.mapID, poiID)
                        if poiInfo then
                            wp_mapid = childMapInfo.mapID
                            wp_x = poiInfo.position.x
                            wp_y = poiInfo.position.y
                            wp_name = poiInfo.name or _G.DELVE_LABEL
                        end
                        break
                    end
                end
                if wp_mapid then break end
            end

            -- Fallback to waypoint or pin position
            wp_mapid = wp_mapid or (self.waypoint and self.waypoint.zone) or uiMapID
            wp_x = wp_x or (self.waypoint and self.waypoint.x) or self:GetPosition()
            wp_y = wp_y or (self.waypoint and self.waypoint.y) or select(2, self:GetPosition())
            wp_name = wp_name or (self.waypoint and self.waypoint.name) or self.name or _G.DELVE_LABEL

            if useTomTom then
                AddTomTomWaypoint(wp_mapid, wp_x, wp_y, wp_name)
            else
                AddNativeWaypoint(wp_mapid, wp_x, wp_y)
            end
        end
    end
end

-- Hook Blizzard's native Delve pins on Zone maps for TomTom support
local function PatchDelveEntrancePins()
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end

    for pin in WorldMapFrame:EnumeratePinsByTemplate("DelveEntrancePinTemplate") do
        if not pin.IPA_CustomClick then
            pin.IPA_CustomClick = true

            pin.OnMouseClickAction = function(self, button)
                local useTomTom = IPASettings and (IPASettings.options.useTomTomDelve == true) and TomTom

                if button == "LeftButton" and useTomTom then
                    local uiMapID = self:GetMap():GetMapID()
                    local areaPoiID = self.poiInfo and self.poiInfo.areaPoiID
                    local poiInfo = areaPoiID and C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, areaPoiID)

                    local wp_x, wp_y, wp_name
                    if poiInfo then
                        wp_x = poiInfo.position.x
                        wp_y = poiInfo.position.y
                        wp_name = poiInfo.name or _G.DELVE_LABEL
                    else
                        wp_x, wp_y = self:GetPosition()
                        wp_name = self.name or _G.DELVE_LABEL
                    end

                    AddTomTomWaypoint(uiMapID, wp_x, wp_y, wp_name)
                else
                    SuperTrackablePinMixin.OnMouseClickAction(self, button)
                end
            end
        end
    end
end

hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
    C_Timer.After(0, PatchDelveEntrancePins)
end)

WorldMapFrame:HookScript("OnShow", function()
    C_Timer.After(0, PatchDelveEntrancePins)
end)