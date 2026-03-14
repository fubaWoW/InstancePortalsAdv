local addonName, IPA = ...

local delveRefreshTimer

-- DataProvider
IPADelveMapDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)

function IPADelveMapDataProviderMixin:RemoveAllData()
    self:GetMap():RemoveAllPinsByTemplate("IPADelveEntrancePinTemplate")
end

function IPADelveMapDataProviderMixin:OnShow()
    self:RegisterEvent("CVAR_UPDATE")
    self:RegisterEvent("SUPER_TRACKING_CHANGED")
end

function IPADelveMapDataProviderMixin:OnHide()
    self:UnregisterEvent("CVAR_UPDATE")
    self:UnregisterEvent("SUPER_TRACKING_CHANGED")
end

function IPADelveMapDataProviderMixin:OnEvent(event, ...)
    if event == "CVAR_UPDATE" then
        local eventName = ...
        if eventName == "showDelveEntrancesOnMap" then
            self:RefreshAllData()
        end
    elseif event == "SUPER_TRACKING_CHANGED" then
        self:OnSuperTrackingChanged()
    end
end

function IPADelveMapDataProviderMixin:OnSuperTrackingChanged()
    for pin in self:GetMap():EnumeratePinsByTemplate("IPADelveEntrancePinTemplate") do
        local isTracked = false
        if C_SuperTrack.IsSuperTrackingMapPin() then
            local pinType, pinID = C_SuperTrack.GetSuperTrackedMapPin()
            if pinType == Enum.SuperTrackingMapPinType.AreaPOI
            and pin.areaPoiID and pin.areaPoiID > 0
            and pinID == pin.areaPoiID then
                isTracked = true
            end
        end
        pin:SetSuperTracked(isTracked)
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

    local function CreatePin(info, waypoint)
        local pin = self:GetMap():AcquirePin("IPADelveEntrancePinTemplate", info)
        pin:UseFrameLevelType("PIN_FRAME_LEVEL_DELVE_ENTRANCE")
        pin.dataProvider = self

        -- Store everything needed
        pin.areaPoiID = info.areaPoiID or 0
        pin.name = info.name or UNKNOWN
        pin.description = info.description or ""
        pin.isSpecialPin = info.isSpecialPin or false
        pin.sourceMapID = info.sourceMapID
        pin.nativePinX = info.nativePinX
        pin.nativePinY = info.nativePinY

        if waypoint then
            pin.waypoint = {
                zone = waypoint.wpzone,
                x = waypoint.wpx,
                y = waypoint.wpy,
                name = waypoint.wpname
            }
        end

        -- Set initial supertrack state
        pin:SetSuperTracked(false)
        if C_SuperTrack.IsSuperTrackingMapPin() then
            local pinType, pinID = C_SuperTrack.GetSuperTrackedMapPin()
            if pinType == Enum.SuperTrackingMapPinType.AreaPOI
            and pin.areaPoiID > 0
            and pinID == pin.areaPoiID then
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
                                local poiInfoCopy = CopyTable(poiInfo)
                                poiInfoCopy.position = CreateVector2D(mapPosition.x, mapPosition.y)
                                poiInfoCopy.dataProvider = self
                                poiInfoCopy.isSpecialPin = false
                                poiInfoCopy.sourceMapID = mapID
                                poiInfoCopy.nativePinX = poiInfo.position.x
                                poiInfoCopy.nativePinY = poiInfo.position.y
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
                poiInfoCopy.isSpecialPin = true
                poiInfoCopy.sourceMapID = specialPinData.instanceZone
                poiInfoCopy.nativePinX = poiInfo.position.x
                poiInfoCopy.nativePinY = poiInfo.position.y
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

-- Add native waypoint
local function AddNativeWaypoint(mapID, x, y)
    if C_Map.CanSetUserWaypointOnMap(mapID) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON)
    end
end

-- Pin Mixin - inherits from MapCanvasPinMixin for all required methods
-- Only taint-prone methods are overridden
IPADelveProviderPinMixin = CreateFromMixins(MapCanvasPinMixin)

-- Override to prevent taint
function IPADelveProviderPinMixin:CheckMouseButtonPassthrough(button) end
function IPADelveProviderPinMixin:SetPassThroughButtons(...) end
function IPADelveProviderPinMixin:UpdateMousePropagation() end

function IPADelveProviderPinMixin:OnLoad()
    self.superTracked = false
end

function IPADelveProviderPinMixin:OnAcquired(info)
    -- Set icon via atlas
    if info and info.atlasName then
        self.Texture:SetAtlas(info.atlasName, true)
        self.HighlightTexture:SetAtlas(info.atlasName, true)
    end
    self.SuperTrackGlow:Hide()
    self.SuperTrackMarker:Hide()
    self.superTracked = false

    -- Set position via map system
    if info and info.position then
        self:SetPosition(info.position.x, info.position.y)
    end

    -- Set scaling
    self:SetScalingLimits(1, 1, 1.2)
end

function IPADelveProviderPinMixin:OnReleased()
    self.SuperTrackGlow:Hide()
    self.SuperTrackMarker:Hide()
    self.superTracked = false
end

function IPADelveProviderPinMixin:SetSuperTracked(tracked)
    self.superTracked = tracked
    if tracked then
        self.SuperTrackGlow:SetSize(40, 40)
        self.SuperTrackGlow:Show()
        self.SuperTrackMarker:Show()
    else
        self.SuperTrackGlow:Hide()
        self.SuperTrackMarker:Hide()
    end
end

function IPADelveProviderPinMixin:IsSuperTracked()
    return self.superTracked or false
end

function IPADelveProviderPinMixin:OnMouseEnter()
    local tooltip = GetAppropriateTooltip()
    tooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(tooltip, self.name or UNKNOWN)
    if self.description and self.description ~= "" then
        GameTooltip_AddNormalLine(tooltip, self.description)
    end
    tooltip:Show()
end

function IPADelveProviderPinMixin:OnMouseLeave()
    GetAppropriateTooltip():Hide()
end

function IPADelveProviderPinMixin:OnMouseClickAction(button)
    if not button then return end

    if button == "LeftButton" then
        local areaPoiID = self.areaPoiID

        if areaPoiID and areaPoiID > 0 then
            securecall(function()
                -- Toggle: if already tracked, clear it
                if self:IsSuperTracked() then
                    C_SuperTrack.ClearAllSuperTracked()
                    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
                else
                    C_SuperTrack.SetSuperTrackedMapPin(
                        Enum.SuperTrackingMapPinType.AreaPOI,
                        areaPoiID
                    )
                    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                end
            end)
        else
            -- Fallback: native waypoint for special pins without areaPoiID
            local wp_mapid = self.sourceMapID or self:GetMap():GetMapID()
            local wp_x = self.nativePinX
            local wp_y = self.nativePinY

            if self.waypoint then
                wp_mapid = self.waypoint.zone or wp_mapid
                wp_x = self.waypoint.x or wp_x
                wp_y = self.waypoint.y or wp_y
            end

            if wp_x and wp_y then
                AddNativeWaypoint(wp_mapid, wp_x, wp_y)
            end
        end
    end
end