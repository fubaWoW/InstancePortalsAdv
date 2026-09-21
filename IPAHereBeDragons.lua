local addonName, IPA = ...

local HBDPins = LibStub("HereBeDragons-Pins-2.0", true)
if not HBDPins then
    return
end

local REF = IPA
local ICON_DUNGEON = "Interface\\MINIMAP\\Dungeon"
local ICON_RAID = "Interface\\MINIMAP\\Raid"
local ICON_TRACKED = "Waypoint-MapPin-Tracked"

local DEFAULT_PIN_SCALE = 1.0
local PIN_SIZE = 32
local MARKER_SIZE = 20
local GLOW_SIZE = 68

local worldPins = {}
local minimapPins = {}
local worldNodes = {}
local minimapNodes = {}

local function CoordKey(x, y)
    return math.floor(x * 10000) * 10000 + math.floor(y * 10000)
end

local function IsSuperTracked(areaPoiID)
    if not areaPoiID or areaPoiID <= 0 then
        return false
    end

    if not C_SuperTrack.IsSuperTrackingMapPin() then
        return false
    end

    local pinType, pinID = C_SuperTrack.GetSuperTrackedMapPin()
    return pinType == Enum.SuperTrackingMapPinType.AreaPOI and pinID == areaPoiID
end

local function GetFinalDescription(atlasName, description)
    if description and description ~= "" then
        return description
    end

    if atlasName == "Raid" then
        return _G.LFG_TYPE_RAID
    end

    return _G.LFG_TYPE_DUNGEON
end

local function AddNode(nodes, mapID, x, y, data)
    if not x or not y then
        return
    end

    local coord = CoordKey(x, y)
    nodes[coord] = nodes[coord] or data
    if data.isSpecialPin then
        nodes[coord] = data
    end

    data.x = x
    data.y = y
    data.coord = coord
end

local function BuildDungeonNodeFromEntrance(entrance, sourceMapID, x, y)
    local areaPoiID = entrance.areaPoiID or 0
    local poiInfo = nil

    if areaPoiID > 0 then
        poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(sourceMapID, areaPoiID)
    end

    return {
        kind = "Dungeon",
        name = (poiInfo and poiInfo.name) or entrance.name or UNKNOWN,
        description = (poiInfo and poiInfo.description) or GetFinalDescription(entrance.atlasName, entrance.description),
        journalInstanceID = entrance.journalInstanceID or 0,
        areaPoiID = areaPoiID,
        atlasName = entrance.atlasName or (poiInfo and poiInfo.atlasName) or "Dungeon",
        sourceMapID = sourceMapID,
        nativePinX = entrance.position and entrance.position.x,
        nativePinY = entrance.position and entrance.position.y,
        poiInfo = poiInfo,
        isSpecialPin = false,
        x = x,
        y = y,
    }
end

local function AddSpecialDungeonPin(nodes, mapID, specialPin)
    if not specialPin.instanceZone or not specialPin.journalInstanceID then
        return
    end

    local entrances = C_EncounterJournal.GetDungeonEntrancesForMap(specialPin.instanceZone) or {}

    for _, entrance in ipairs(entrances) do
        if entrance.journalInstanceID == specialPin.journalInstanceID then
            local node = BuildDungeonNodeFromEntrance(
                entrance,
                specialPin.instanceZone,
                specialPin.x,
                specialPin.y
            )

            node.isSpecialPin = true
            node.x = specialPin.x
            node.y = specialPin.y
            node.sourceMapID = specialPin.instanceZone

            -- Prefer Blizzard's native atlas. Use the special-pin database
            -- value only when Blizzard does not provide one.
            local atlasName = entrance.atlasName

            if not atlasName or atlasName == "" then
                atlasName = specialPin.atlasName
            end

            if not atlasName or atlasName == "" then
                atlasName = "Dungeon"
            end

            node.atlasName = atlasName

            -- Keep the explicitly configured POI ID when present.
            if specialPin.areaPoiID then
                node.areaPoiID = specialPin.areaPoiID
                node.poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(
                    specialPin.instanceZone,
                    specialPin.areaPoiID
                )

                if node.poiInfo then
                    node.name = node.poiInfo.name or node.name
                    node.description = node.poiInfo.description or node.description
                end
            end

            AddNode(nodes, mapID, specialPin.x, specialPin.y, node)
            return
        end
    end
end

local function AddSpecialDelvePin(nodes, mapID, specialPin)
    if not specialPin.instanceZone or not specialPin.areaPoiID then
        return
    end

    local areaPoiID = specialPin.areaPoiID
    local atlasName = specialPin.atlasName or "delves-regular"

    -- Bountiful Delve pins are intentionally disabled.
    -- Keep using the regular Delve POI for normal Delve pins.

    local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(specialPin.instanceZone, areaPoiID)
    if not poiInfo then
        return
    end

    AddNode(nodes, mapID, specialPin.x, specialPin.y, {
        kind = "Delve",
        name = poiInfo.name or UNKNOWN,
        description = poiInfo.description or "",
        areaPoiID = areaPoiID,
        atlasName = atlasName,
        sourceMapID = specialPin.instanceZone,
        nativePinX = poiInfo.position and poiInfo.position.x,
        nativePinY = poiInfo.position and poiInfo.position.y,
        poiInfo = poiInfo,
        isSpecialPin = true,
    })
end

local function BuildDungeonNodes(mapID, mapInfo, nodes)
    if IPA.mapBlacklist_Dungeon and IPA.mapBlacklist_Dungeon[mapID] then
        return
    end

    -- if not GetCVarBool("showDungeonEntrancesOnMap") then
        -- return
    -- end

    if not IPASettings.options.showOwnPins then
        return
    end

    local isContinent = mapInfo.mapType == Enum.UIMapType.Continent
    local isZone = mapInfo.mapType == Enum.UIMapType.Zone
    if not (isContinent or isZone) then
        return
    end

    local specialPinsForMap = IPA.specialPin_Dungeon and IPA.specialPin_Dungeon[mapID]

    if isContinent then
        local mapChildren = C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone) or {}
        local processedIDs = {}

        for _, childMapInfo in ipairs(mapChildren) do
            local sourceMapID = childMapInfo.mapID
            local entrances = C_EncounterJournal.GetDungeonEntrancesForMap(sourceMapID) or {}

            for _, entrance in ipairs(entrances) do
                local journalID = entrance.journalInstanceID

                if journalID and not processedIDs[journalID] then
                    processedIDs[journalID] = true

                    local overridden = false
                    if specialPinsForMap then
                        for _, specialPin in ipairs(specialPinsForMap) do
                            if specialPin.journalInstanceID == journalID then
                                overridden = true
                                break
                            end
                        end
                    end

                    -- Project normal Dungeon pins from their native zone
                    -- position onto the continent map. If Blizzard already
                    -- provides that Dungeon natively on the target map, do not
                    -- create a duplicate. Special Dungeon pins remain handled
                    -- separately below.
                    if not overridden and entrance.position then
                        local nativeOnTargetMap = false
                        local targetEntrances = C_EncounterJournal.GetDungeonEntrancesForMap(mapID) or {}

                        for _, targetEntrance in ipairs(targetEntrances) do
                            if targetEntrance.journalInstanceID == journalID then
                                nativeOnTargetMap = true
                                break
                            end
                        end

                        if not nativeOnTargetMap then
                            local pos = CreateVector2D(entrance.position.x, entrance.position.y)
                            local continentID, worldPosition = C_Map.GetWorldPosFromMapPos(sourceMapID, pos)
                            local _, mapPosition = C_Map.GetMapPosFromWorldPos(continentID, worldPosition, mapID)

                            if mapPosition then
                                AddNode(nodes, mapID, mapPosition.x, mapPosition.y,
                                    BuildDungeonNodeFromEntrance(entrance, sourceMapID, mapPosition.x, mapPosition.y))
                            end
                        end
                    end
                end
            end
        end
    else
        -- Native Dungeon entrances are already represented by Blizzard's
        -- native data on the zone map. IPA must not create a duplicate here.
        -- Special Dungeon pins are handled separately below.
    end

    if specialPinsForMap then
        for _, specialPin in ipairs(specialPinsForMap) do
            AddSpecialDungeonPin(nodes, mapID, specialPin)
        end
    end
end

local function BuildDelveNodes(mapID, mapInfo, nodes)
    if IPA.mapBlacklist_Delve and IPA.mapBlacklist_Delve[mapID] then
        return
    end

    -- if not GetCVarBool("showDelveEntrancesOnMap") then
        -- return
    -- end

    if not IPASettings.options.showOwnDelvePins then
        return
    end

    local isContinent = mapInfo.mapType == Enum.UIMapType.Continent
    local isZone = mapInfo.mapType == Enum.UIMapType.Zone
    if not (isContinent or isZone) then
        return
    end

    local specialPinsForMap = IPA.specialPin_Delve and IPA.specialPin_Delve[mapID]

    if isContinent then
        local mapChildren = C_Map.GetMapChildrenInfo(mapID, Enum.UIMapType.Zone) or {}
        local processedIDs = {}

        for _, childMapInfo in ipairs(mapChildren) do
            local sourceMapID = childMapInfo.mapID
            local areaPOIs = C_AreaPoiInfo.GetDelvesForMap(sourceMapID) or {}

            for _, areaPoiID in ipairs(areaPOIs) do
                if not processedIDs[areaPoiID] then
                    processedIDs[areaPoiID] = true

                    local overridden = false
                    if specialPinsForMap then
                        for _, specialPin in ipairs(specialPinsForMap) do
                            if specialPin.areaPoiID == areaPoiID then
                                overridden = true
                                break
                            end
                        end
                    end


                    -- Project normal Delve pins from their native zone
                    -- position onto the continent map. If Blizzard already
                    -- provides that Delve natively on the target map, do not
                    -- create a duplicate. Special Delve pins are handled
                    -- separately below and remain unaffected.
                    if not overridden then
                        local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(sourceMapID, areaPoiID)

                        -- Bountiful Delves are identified by their actual
                        -- Delve POI atlas, not by specialPin_Delve.
                        if poiInfo
                            and poiInfo.atlasName ~= "delves-bountiful"
                            and poiInfo.position then
                            local nativeOnTargetMap = false
                            local targetPOIs = C_AreaPoiInfo.GetDelvesForMap(mapID) or {}

                            for _, targetAreaPoiID in ipairs(targetPOIs) do
                                if targetAreaPoiID == areaPoiID then
                                    nativeOnTargetMap = true
                                    break
                                end
                            end

                            if not nativeOnTargetMap then
                                local continentID, worldPosition =
                                    C_Map.GetWorldPosFromMapPos(sourceMapID, poiInfo.position)
                                local _, mapPosition =
                                    C_Map.GetMapPosFromWorldPos(continentID, worldPosition, mapID)

                                if mapPosition then
                                    AddNode(nodes, mapID, mapPosition.x, mapPosition.y, {
                                        kind = "Delve",
                                        name = poiInfo.name or UNKNOWN,
                                        description = poiInfo.description or "",
                                        areaPoiID = areaPoiID,
                                        atlasName = poiInfo.atlasName or "delves-regular",
                                        sourceMapID = sourceMapID,
                                        nativePinX = poiInfo.position.x,
                                        nativePinY = poiInfo.position.y,
                                        poiInfo = poiInfo,
                                        isSpecialPin = false,
                                    })
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        -- Native Delve POIs are already represented by Blizzard's native
        -- data on the zone map. IPA must not create a duplicate here.
        -- Special Delve pins are handled separately below.
    end

    if specialPinsForMap then
        for _, specialPin in ipairs(specialPinsForMap) do
            AddSpecialDelvePin(nodes, mapID, specialPin)
        end
    end
end

local function BuildNodes(mapID)
    local result = {}
    local mapInfo = C_Map.GetMapInfo(mapID)

    if not mapInfo then
        return result
    end

    BuildDungeonNodes(mapID, mapInfo, result)
    BuildDelveNodes(mapID, mapInfo, result)

    return result
end

local function GetNode(nodes, x, y)
    if not nodes then
        return nil
    end

    return nodes[CoordKey(x, y)]
end

local function AddNativeWaypoint(node, fallbackMapID)
    local mapID = node.sourceMapID or fallbackMapID
    local x = node.nativePinX
    local y = node.nativePinY

    if node.waypoint then
        mapID = node.waypoint.zone or mapID
        x = node.waypoint.x or x
        y = node.waypoint.y or y
    end

    if not mapID or not x or not y then
        return
    end

    if C_Map.CanSetUserWaypointOnMap(mapID) then
        C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y))
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        PlaySound(SOUNDKIT.UI_MAP_WAYPOINT_SUPER_TRACK_ON)
    end
end

local function SecureOpenEncounterJournal(journalInstanceID)
    if not journalInstanceID or journalInstanceID <= 0 then
        return
    end

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

local function SetTextureForNode(pin, node)
    local texture = pin.IPATexture

    if node.kind == "Delve" then
        texture:SetAtlas(node.atlasName or "delves-regular")
    elseif node.atlasName == "Raid" then
        texture:SetTexture(ICON_RAID)
    elseif node.atlasName and node.atlasName ~= "" and node.atlasName ~= "Dungeon" then
        texture:SetAtlas(node.atlasName)
    else
        texture:SetTexture(ICON_DUNGEON)
    end
end

local function UpdateTracked(pin, node)
    if not node then
        if pin.IPATrackedOverlay then
            pin.IPATrackedOverlay:Hide()
        end
        if pin.IPATrackedGlow then
            pin.IPATrackedGlow:Hide()
        end
        return
    end

    if not IsSuperTracked(node.areaPoiID) then
        if pin.IPATrackedOverlay then
            pin.IPATrackedOverlay:Hide()
        end
        if pin.IPATrackedGlow then
            pin.IPATrackedGlow:Hide()
        end
        return
    end

    if not pin.IPATrackedGlow then
        local glow = pin:CreateTexture(nil, "BACKGROUND")
        glow:SetSize(GLOW_SIZE, GLOW_SIZE)
        glow:SetAtlas("UI-QuestPoi-OuterGlow")
        glow:SetPoint("CENTER", pin.IPATexture, "CENTER")
        pin.IPATrackedGlow = glow
    end

    if not pin.IPATrackedOverlay then
        local overlayFrame = CreateFrame("Frame", nil, pin)
        overlayFrame:SetSize(MARKER_SIZE, MARKER_SIZE)
        overlayFrame:SetFrameStrata(pin:GetFrameStrata())
        overlayFrame:SetFrameLevel(pin:GetFrameLevel() + 10)
        overlayFrame:SetPoint("CENTER", pin.IPATexture, "BOTTOMRIGHT", -5, 5)

        local overlay = overlayFrame:CreateTexture(nil, "ARTWORK", nil, 7)
        overlay:SetAtlas(ICON_TRACKED)
        overlay:SetAllPoints(overlayFrame)

        pin.IPATrackedOverlay = overlayFrame
    end

    pin.IPATrackedGlow:SetSize(GLOW_SIZE, GLOW_SIZE)
    pin.IPATrackedGlow:Show()

    pin.IPATrackedOverlay:SetSize(MARKER_SIZE, MARKER_SIZE)
    pin.IPATrackedOverlay:ClearAllPoints()
    pin.IPATrackedOverlay:SetPoint("CENTER", pin.IPATexture, "BOTTOMRIGHT", -8, 8)
    pin.IPATrackedOverlay:SetFrameStrata(pin:GetFrameStrata())
    pin.IPATrackedOverlay:SetFrameLevel(pin:GetFrameLevel() + 10)
    pin.IPATrackedOverlay:Show()
end

local function CreatePin(node)
    local pin = CreateFrame("Button", nil)
    pin:SetSize(PIN_SIZE, PIN_SIZE)
    pin:SetFrameStrata("MEDIUM")
    pin:EnableMouse(true)
    pin:RegisterForClicks("AnyUp")

    local texture = pin:CreateTexture(nil, "ARTWORK")
    texture:SetSize(PIN_SIZE, PIN_SIZE)
    texture:SetPoint("CENTER")
    pin.IPATexture = texture

    SetTextureForNode(pin, node)
    pin.IPANodeX = node.x
    pin.IPANodeY = node.y

    pin.HasDisplayName = function()
        return node.name and node.name ~= ""
    end

    pin.GetDisplayName = function()
        return node.name
    end

    pin:SetScript("OnEnter", function(self)
        local tooltip = GameTooltip
        tooltip:SetOwner(self, "ANCHOR_RIGHT")

        local name = node.name
        if not name or name == "" then
            name = _G.DUNGEON_MAP_PIN_FALLBACK_NAME
        end

        GameTooltip_SetTitle(tooltip, name)

        if node.kind == "Dungeon" then
            -- Blizzard uses the same internal Dungeon node type for both
            -- Dungeons and Raids. The atlas identifies Raid pins.
            if node.atlasName == "Raid" then
                GameTooltip_AddNormalLine(
                    tooltip,
                    _G.RAID
                )
            else
                GameTooltip_AddNormalLine(
                    tooltip,
                    _G.DUNGEON_MAP_PIN_FALLBACK_NAME
                )
            end

            GameTooltip_AddInstructionLine(
                tooltip,
                _G.DUNGEON_POI_TOOLTIP_INSTRUCTION_LINE,
                false
            )
        elseif node.kind == "Delve" then
            -- Delves use their actual POI description and never use the
            -- Dungeon instruction line.
            local description = node.description

            if description and description ~= "" then
                GameTooltip_AddNormalLine(tooltip, description)
            end
        end

        tooltip:Show()
    end)

    pin:SetScript("OnLeave", function(self)
        GameTooltip:Hide()

        local tooltip = GetAppropriateTooltip()
        if tooltip and tooltip:GetOwner() == self then
            tooltip:Hide()
        end
    end)

    pin:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if node.areaPoiID and node.areaPoiID > 0 then
                if IsSuperTracked(node.areaPoiID) then
                    securecall(function()
                        C_SuperTrack.ClearAllSuperTracked()
                        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
                    end)
                else
                    securecall(function()
                        C_SuperTrack.SetSuperTrackedMapPin(
                            Enum.SuperTrackingMapPinType.AreaPOI,
                            node.areaPoiID
                        )
                        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                    end)
                end
				
				if GameTooltip:IsOwned(self) then
					GameTooltip:Hide()
					self:GetScript("OnEnter")(self)
				end
				
            else
                AddNativeWaypoint(node, node.sourceMapID)
            end
        elseif button == "RightButton" and node.kind == "Dungeon" then
            SecureOpenEncounterJournal(node.journalInstanceID)
        end
    end)

    UpdateTracked(pin, node)
    return pin
end

local function ClearWorldPins()
    for pin in pairs(worldPins) do
        HBDPins:RemoveWorldMapIcon(REF, pin)
        pin:Hide()
    end
    wipe(worldPins)
    worldNodes = {}
end

local function ClearMinimapPins()
    for pin in pairs(minimapPins) do
        HBDPins:RemoveMinimapIcon(REF, pin)
        pin:Hide()
    end
    wipe(minimapPins)
    minimapNodes = {}
end

local function RefreshWorldMap()
    local mapID = WorldMapFrame and WorldMapFrame:GetMapID()
    if not mapID then
        return
    end

    ClearWorldPins()
    worldNodes = BuildNodes(mapID)

    local showFlag = nil
    local mapInfo = C_Map.GetMapInfo(mapID)
    if mapInfo and mapInfo.mapType == Enum.UIMapType.Zone then
        showFlag = HBD_PINS_WORLDMAP_SHOW_PARENT
    end

    for _, node in pairs(worldNodes) do
        local pin = CreatePin(node)
        pin:SetParent(WorldMapFrame)
        local ok = HBDPins:AddWorldMapIconMap(
            REF,
            pin,
            mapID,
            node.x,
            node.y,
            showFlag,
            node.kind == "Delve" and "PIN_FRAME_LEVEL_DELVE_ENTRANCE" or "PIN_FRAME_LEVEL_DUNGEON_ENTRANCE"
        )

        if ok then
            worldPins[pin] = true
        else
            pin:Hide()
        end
    end
end

local function RefreshMinimap()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then
        return
    end

    ClearMinimapPins()

    if not (IPASettings and IPASettings.options and IPASettings.options.showOwnMinimapPins) then
        return
    end

    minimapNodes = BuildNodes(mapID)

    for _, node in pairs(minimapNodes) do
        local pin = CreatePin(node)
        local ok = HBDPins:AddMinimapIconMap(
            REF,
            pin,
            mapID,
            node.x,
            node.y,
            false,
            false
        )

        if ok then
            minimapPins[pin] = true
        else
            pin:Hide()
        end
    end
end

local function RefreshAll()
    RefreshWorldMap()
    RefreshMinimap()
end

local function UpdateTrackedPins()
    for pin in pairs(worldPins) do
        local node = worldNodes and GetNode(worldNodes, pin.IPANodeX, pin.IPANodeY)
        UpdateTracked(pin, node)
    end

    for pin in pairs(minimapPins) do
        local node = minimapNodes and GetNode(minimapNodes, pin.IPANodeX, pin.IPANodeY)
        UpdateTracked(pin, node)
    end
end

local function RefreshForSettings()
    C_Timer.After(0, RefreshAll)
end

function IPA:NotifyUpdate()
    RefreshForSettings()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
eventFrame:RegisterEvent("SUPER_TRACKING_CHANGED")

if WorldMapFrame then
    WorldMapFrame:HookScript("OnShow", function()
        C_Timer.After(0, RefreshWorldMap)
    end)

    hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
        C_Timer.After(0, RefreshWorldMap)
    end)
end

eventFrame:SetScript("OnEvent", function(_, event, cvarName)
    if event == "SUPER_TRACKING_CHANGED" then
        UpdateTrackedPins()
    else
        C_Timer.After(0, RefreshAll)
    end
end)

IPA.HBDPins = HBDPins

C_Timer.After(0, RefreshAll)