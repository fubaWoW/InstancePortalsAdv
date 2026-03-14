local addonName, IPA = ...

local refreshTimer

-- DataProvider
IPAInstancePortalMapDataProviderMixin = CreateFromMixins(MapCanvasDataProviderMixin)

function IPAInstancePortalMapDataProviderMixin:RemoveAllData()
    self:GetMap():RemoveAllPinsByTemplate("IPAInstancePortalPinTemplate")
end

function IPAInstancePortalMapDataProviderMixin:OnShow()
    self:RegisterEvent("CVAR_UPDATE")
    self:RegisterEvent("SUPER_TRACKING_CHANGED")
end

function IPAInstancePortalMapDataProviderMixin:OnHide()
    self:UnregisterEvent("CVAR_UPDATE")
    self:UnregisterEvent("SUPER_TRACKING_CHANGED")
end

function IPAInstancePortalMapDataProviderMixin:OnEvent(event, ...)
    if event == "CVAR_UPDATE" then
        local eventName = ...
        if eventName == "showDungeonEntrancesOnMap" then
            self:RefreshAllData()
        end
    elseif event == "SUPER_TRACKING_CHANGED" then
        self:OnSuperTrackingChanged()
    end
end

function IPAInstancePortalMapDataProviderMixin:OnSuperTrackingChanged()
    for pin in self:GetMap():EnumeratePinsByTemplate("IPAInstancePortalPinTemplate") do
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
    if not mapInfo then return end

    local isContinent = mapInfo.mapType == Enum.UIMapType.Continent
    local isZone = mapInfo.mapType == Enum.UIMapType.Zone
    if not (isContinent or isZone) then return end

    local mapChildren = C_Map.GetMapChildrenInfo(uiMapID, Enum.UIMapType.Zone) or {}
    local specialPinsForMap = IPA.specialPin_Dungeon and IPA.specialPin_Dungeon[uiMapID]
    if #mapChildren == 0 and not specialPinsForMap then return end

    local function CreatePin(info, waypoint)
        local pin = self:GetMap():AcquirePin("IPAInstancePortalPinTemplate", info)
		pin:UseFrameLevelType("PIN_FRAME_LEVEL_DUNGEON_ENTRANCE")
        pin.dataProvider = self
		
        -- Store everything needed
        pin.journalInstanceID = info.journalInstanceID or 0
        pin.areaPoiID = info.areaPoiID or 0
        pin.atlasName = info.atlasName
        pin.name = info.name or UNKNOWN
        pin.description = info.description or ""
        pin.isRaid = info.atlasName == "Raid"
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

    -- Process dungeon entrances for child maps (Continent only!)
    if isContinent and #mapChildren > 0 then
        local processedIDs = {}

        for _, childMapInfo in ipairs(mapChildren) do
            local mapID = childMapInfo.mapID
            local dungeonEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(mapID)

            for _, entrance in ipairs(dungeonEntrances) do
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
                        local continentID, worldPosition = C_Map.GetWorldPosFromMapPos(mapID, pos_vector)
                        local _, mapPosition = C_Map.GetMapPosFromWorldPos(continentID, worldPosition, uiMapID)
                        if mapPosition then
                            local finalDesc = entrance.description
                            if not finalDesc or finalDesc == "" then
                                finalDesc = (entrance.atlasName == "Raid") and _G.LFG_TYPE_RAID or _G.LFG_TYPE_DUNGEON
                            end

                            CreatePin({
                                position = CreateVector2D(mapPosition.x, mapPosition.y),
                                areaPoiID = entrance.areaPoiID,
                                name = entrance.name,
                                description = finalDesc,
                                journalInstanceID = entrance.journalInstanceID,
                                atlasName = entrance.atlasName,
                                isSpecialPin = false,
                                sourceMapID = mapID,
                                nativePinX = entrance.position.x,
                                nativePinY = entrance.position.y,
                            })
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
                name = EJ_GetInstanceInfo(specialPinData.journalInstanceID) or UNKNOWN,
                isSpecialPin = true,
                sourceMapID = specialPinData.instanceZone,
                nativePinX = nil,
                nativePinY = nil,
            }

            if specialPinData.instanceZone and type(specialPinData.instanceZone) == "number" then
                for _, entrance in ipairs(C_EncounterJournal.GetDungeonEntrancesForMap(specialPinData.instanceZone)) do
                    if entrance.journalInstanceID == specialPinData.journalInstanceID then
                        local finalDesc = entrance.description
                        if not finalDesc or finalDesc == "" then
                            finalDesc = (entrance.atlasName == "Raid") and _G.LFG_TYPE_RAID or _G.LFG_TYPE_DUNGEON
                        end
                        entranceInfo.areaPoiID = entrance.areaPoiID
                        entranceInfo.name = entrance.name
                        entranceInfo.description = finalDesc
                        entranceInfo.atlasName = entrance.atlasName
                        entranceInfo.nativePinX = entrance.position.x
                        entranceInfo.nativePinY = entrance.position.y
                        break
                    end
                end
            end

            CreatePin(entranceInfo, specialPinData)
        end
    end
end

function IPAInstancePortalMapDataProviderMixin:RefreshAllData(fromOnShow)
    if refreshTimer then refreshTimer:Cancel() end
    refreshTimer = C_Timer.NewTimer(0, function()
        refreshTimer = nil
        xpcall(function() DoRefresh(self) end, geterrorhandler())
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

-- Secure EncounterJournal
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

-- Pin Mixin - inherits from MapCanvasPinMixin for all required methods
-- Only taint-prone methods are overridden
IPAInstancePortalProviderPinMixin = CreateFromMixins(MapCanvasPinMixin)

-- Override to prevent taint
function IPAInstancePortalProviderPinMixin:CheckMouseButtonPassthrough(button) end
function IPAInstancePortalProviderPinMixin:SetPassThroughButtons(...) end
function IPAInstancePortalProviderPinMixin:UpdateMousePropagation() end

function IPAInstancePortalProviderPinMixin:OnLoad()
    self.superTracked = false
end

function IPAInstancePortalProviderPinMixin:OnAcquired(info)
    -- Set icon via atlas
    if info and info.atlasName then
		self.Texture:SetAtlas(info.atlasName, true)
		self.HighlightTexture:SetAtlas(info.atlasName, true)
	end
    self.SuperTrackGlow:Hide()
    self.SuperTrackMarker:Hide()
    self.superTracked = false

    -- Set position via map system (handles scaling correctly)
    if info and info.position then
        self:SetPosition(info.position.x, info.position.y)
    end
	
    -- Set scaling
    self:SetScalingLimits(1, 1, 1.2)
end

function IPAInstancePortalProviderPinMixin:OnReleased()
    self.SuperTrackGlow:Hide()
    self.SuperTrackMarker:Hide()
    self.superTracked = false
end

function IPAInstancePortalProviderPinMixin:SetSuperTracked(tracked)
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

function IPAInstancePortalProviderPinMixin:IsSuperTracked()
    return self.superTracked or false
end

-- Blizzard calls OnMouseEnter/OnMouseLeave via SetScript in AcquirePin
function IPAInstancePortalProviderPinMixin:OnMouseEnter()
    local tooltip = GetAppropriateTooltip()
    tooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(tooltip, self.name or UNKNOWN)
    if self.description and self.description ~= "" then
        GameTooltip_AddNormalLine(tooltip, self.description)
    end
    if self.journalInstanceID and self.journalInstanceID > 0 then
        GameTooltip_AddInstructionLine(tooltip, "Right-Click: Open Encounter Journal", false)
    end
    tooltip:Show()
end

function IPAInstancePortalProviderPinMixin:OnMouseLeave()
    GetAppropriateTooltip():Hide()
end

-- Find matching native Blizzard DungeonEntrancePinTemplate on current map
function IPAInstancePortalProviderPinMixin:FindNativePin()
    for pin in WorldMapFrame:EnumeratePinsByTemplate("DungeonEntrancePinTemplate") do
        if pin.journalInstanceID == self.journalInstanceID then
            return pin
        end
    end
    return nil
end

function IPAInstancePortalProviderPinMixin:OnMouseClickAction(button)
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

	elseif button == "RightButton" then
		if self.journalInstanceID and self.journalInstanceID > 0 then
			SecureOpenEncounterJournal(self.journalInstanceID)
		end
	end
end