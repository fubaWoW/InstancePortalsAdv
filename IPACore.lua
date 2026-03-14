local addonName, IPA = ...

_G["InstancePortalsAdv"] = IPA

function IPA:DebugPrint(debugtext, force)
    if (IPASettings and IPASettings.options and IPASettings.options.debug == true) or (force == true) then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8000IPADebug\[|r"..debugtext.."|cffff8000\]")
    end
end

local function ReCreateDatabase()
    IPASettings = IPA.DefaultSettings
end

-- Check if value {v} already exists in table {t}
function IPA:tableContains(t, v)
    for _, item in ipairs(t) do
        if item == v then
            return true
        end
    end
    return false
end

local coreFrame = CreateFrame("FRAME")
coreFrame:RegisterEvent("PLAYER_LOGIN")
coreFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then

        -- Version check / DB reset
        if IPASettings then
            if not IPASettings.version or IPASettings.version ~= IPA.DefaultSettings.version then
                IPA:DebugPrint("Instance Portal Advanced Settings are reset!", true)
                IPA:DebugPrint("Use the Settings Page at \"Options >> AddOns\" from now on.", true)
                ReCreateDatabase()
            end
        else
            ReCreateDatabase()
        end

        -- Register DataProviders
        WorldMapFrame:AddDataProvider(CreateFromMixins(IPAInstancePortalMapDataProviderMixin))
        WorldMapFrame:AddDataProvider(CreateFromMixins(IPADelveMapDataProviderMixin))

    end
end)