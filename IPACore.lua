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

-- check if "value {v}" already exists in "table {t}"
function IPA:tableContains(t, v)
    for _, item in ipairs(t) do
        if item == v then
            return true
        end
    end
    return false
end

function InstancePortalAdvUI_OnLoad(self)
	self:RegisterEvent("PLAYER_LOGIN")
	
	IPA:DebugPrint("InstancePortalAdvUI_OnLoad()")
	WorldMapFrame:AddDataProvider(CreateFromMixins(IPAInstancePortalMapDataProviderMixin));
end

function InstancePortalAdvUI_OnEvent(event, arg1)
	if event == "PLAYER_LOGIN" then
		if IPASettings then
			if not (IPASettings.version) then
				IPA:DebugPrint("Instance Portal Advanced Settings are resetted!", true)
				IPA:DebugPrint("Use the NEW Settings Page at \"Options >> AddOns\" from now on.", true)
				ReCreateDatabase()
			elseif IPASettings.version and IPASettings.version ~= IPA.DefaultSettings.version then
				-- do something if "Database Version" is another version and maybe need attention?!
				IPA:DebugPrint("Instance Portal Advanced Settings are resetted!", true)
				IPA:DebugPrint("Use the NEW Settings Page at \"Options >> AddOns\" from now on.", true)
				ReCreateDatabase()
			end
		else
			ReCreateDatabase()
		end
	end
end