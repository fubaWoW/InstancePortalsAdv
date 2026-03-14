local addonName, IPA = ...


IPA.mapBlacklist_Dungeon = {
    [947] = true,   -- Azeroth
}

IPA.mapBlacklist_Delve = {
    [12]  = true,   -- Kalimdor
    [13]  = true,   -- Eastern Kingdoms
    [947] = true,   -- Azeroth
}

IPA.specialPin_Delve = {

	[2274]={ -- Khaz Algar
		{
			areaPoiID = 8140,    -- Sidestreet Sluice
			x = 0.8010,
			y = 0.7020,
			instanceZone = 2346,    -- Undermine
			atlasName = "delves-regular",
		},
		
		{
			areaPoiID = 8274,    -- Archival Assault
			x = 0.1760,
			y = 0.2050,
			instanceZone = 2371,    -- K'aresh
			atlasName = "delves-regular",
		},
		
		{
			areaPoiID = 8323,    -- Voidrazor Sanctuary
			x = 0.1820,
			y = 0.2370,
			instanceZone = 2371,    -- K'aresh
			atlasName = "delves-regular",
		},
	},
	
	[2537]={ -- Quel'Thalas
		{
			areaPoiID = 8431,    -- Shadowguard Point
			x = 0.5050,
			y = 0.2400,
			instanceZone = 2405,    -- Voidstorm
			atlasName = "delves-regular",
		},
		
		{
			areaPoiID = 8429,    -- Sunkiller Sanctum
			x = 0.5330,
			y = 0.2400,
			instanceZone = 2405,    -- Voidstorm
			atlasName = "delves-regular",
		},
		
		{
			areaPoiID = 8435,    -- The Gulf of Memory
			x = 0.8000,
			y = 0.1750,
			instanceZone = 2413,    -- Harandar
			atlasName = "delves-regular",
		},
		
		{
			areaPoiID = 8433,    -- The Grudge Pit
			x = 0.8450,
			y = 0.1900,
			instanceZone = 2413,    -- Harandar
			atlasName = "delves-regular",
		},
	},
	

}


IPA.specialPin_Dungeon = {

	----------------------------------------
	--     Eastern Kingdoms Specials      --
	----------------------------------------

	[13]={ -- Eastern Kingdoms
		
		{
			journalInstanceID = 1300,    -- Magisters' Terrace
			x = 0.5746,
			y = 0.0265,
			instanceZone = 2424,    -- Isle of Quel'Danas
			atlasName = "Dungeon",
		},
				
		{
			journalInstanceID = 1304,    -- Murder Row
			x = 0.5740,
			y = 0.1349,
			instanceZone = 2393,    -- Silvermoon City
			atlasName = "Dungeon",
		},
				
	
		{ 
			journalInstanceID = 1299, 		-- Windrunner Spire
			x = 0.5320,
			y = 0.2580,
			instanceZone = 2395,			-- Eversong Woods
			atlasName = "Dungeon",
		},
		
		{
			journalInstanceID = 1308,    -- March on Quel'Danas
			x = 0.5662,
			y = 0.0802,
			instanceZone = 2424,    -- Isle of Quel'Danas
			atlasName = "Raid",
		},
		{
			journalInstanceID = 1315,    -- Maisara Caverns
			x = 0.6371,
			y = 0.2318,
			instanceZone = 2437,    -- Zul'Aman
			atlasName = "Dungeon",
		},
		
		
		-- Voidstorm Dungeons & Raids (Midnight) -- disabled, look stupid... :D
		--[[
		{
			journalInstanceID = 1307,    -- Voidspire
			x = 0.6600,
			y = 0.1300,
			instanceZone = 2405,    -- Voidstorm
			atlasName = "Raid",
		},
		
		{
			journalInstanceID = 1316,    -- Nexus-Point Xenas
			x = 0.6800,
			y = 0.1150,
			instanceZone = 2405,    -- Voidstorm
			atlasName = "Dungeon",
		},
		{
			journalInstanceID = 1313,    -- Voidscar Arena
			x = 0.6650,
			y = 0.0800,
			instanceZone = 2444,    -- Slayer's Rise (Voidstorm)
			atlasName = "Dungeon",
		},
		]]
		
	},

	----------------------------------------
	--         Classic Instances          --
	----------------------------------------

	----------------------------------------
	--   The Burning Crusade Instances    --
	----------------------------------------
	----------------------------------------
	--  Wrath of the Lich King Instances  --
	----------------------------------------
	
	----------------------------------------
	--        Cataclysm Instances         --
	----------------------------------------

	[948]={ -- The Maelstrom
	
		{ 
			journalInstanceID = 67,	-- The stonecore
			x = 0.5100,
			y = 0.2850,
			instanceZone = 207,			-- Deepholme
			atlasName = "Dungeon",
		},
		
	},

	----------------------------------------
	--   Warlords of Draenor Instances    --
	----------------------------------------

	----------------------------------------
	--          Legion Instances          --
	----------------------------------------
	
	[619]={ -- Broken Isles Continent
	
		{ 
			journalInstanceID = 945,	-- Seat of the Triumvirate
			x = 0.9,
			y = 0.1,
			instanceZone = 882,				-- Argus, Eredat
			atlasName = "Dungeon",
		},
		
		{ 
			journalInstanceID = 946,	-- Antorus, The Burning Throne
			x = 0.8300,
			y = 0.2200,
			instanceZone = 885,				-- Argus, Antoran Wastes
			atlasName = "Raid",
		},
		
		{ 
			journalInstanceID = 777,	-- Assault on Violet Hold (Dalaran: Broken Isles)
			x = 0.4550,
			y = 0.6540,
			instanceZone = 627,				-- Dalaran: Broken Isles
			atlasName = "Dungeon",
		},
		
	},
	
	[905]={ -- Argus Continent Map
		{ 
			journalInstanceID = 945,	-- Seat of the Triumvirate
			x = 0.5400,
			y = 0.3900,
			instanceZone = 882,				-- Argus, Eredat
			atlasName = "Dungeon",
		},
		
		{ 
			journalInstanceID = 946,	-- Antorus, The Burning Throne
			x = 0.3200,
			y = 0.6800,
			instanceZone = 885,				-- Argus, Antoran Wastes
			atlasName = "Raid",
		},	
	},
	
	----------------------------------------
	--    Battle for Azeroth Instances    --
	----------------------------------------
	
	[875]={ -- Zandalar
		{
			journalInstanceID = 1179,	-- The Eternal Palace
			x = 0.8700,
			y = 0.1100,
			instanceZone = nil,				-- hidden Dungeon
			atlasName = "Raid",
			wpzone = 1355,						-- override waypoint position mapid
			wpx = 0.5000,							-- override waypoint position x
			wpy = 0.1000,							-- override waypoint position y
			wpname = nil,							-- here we "can" override names or nil for automatic name
		},
	},
	
	[876]={ -- Kul Tiras
		{
			journalInstanceID = 1179,	-- The Eternal Palace
			x = 0.8700,
			y = 0.1100,
			instanceZone = nil,				-- hidden Dungeon
			atlasName = "Raid",
			wpzone = 1355,						-- override waypoint position mapid
			wpx = 0.5040,							-- override waypoint position x
			wpy = 0.0990,							-- override waypoint position y
			wpname = nil,							-- here we "can" override names or nil for automatic name
		},
	},
	
	----------------------------------------
	--       Shadowlands Instances        --
	----------------------------------------

	[1550]={ -- Shadowlands Contient
	
		{ 
			journalInstanceID = 1194,	-- Tazavesh, the Veiled Market
			x = 0.31940000,
			y = 0.76010000,
			instanceZone = nil,				-- hidden Dungeon
			atlasName = "Dungeon",
		},
		
		{ 
			journalInstanceID = 1195,	-- Sepulcher of the First Ones
			x = 0.89000000,
			y = 0.80000000,
			instanceZone = 1970,
			atlasName = "Raid",
		},
		
	},
	
	----------------------------------------
	--       Dragonflight Instances       --
	----------------------------------------
	
		[1978]={ -- Dragon Isles
		{
			journalInstanceID = 1208,		-- Aberrus, the Shadowed Crucible
			x = 0.8700,
			y = 0.7400,
			instanceZone = 2133,				-- Zaralek Caverns
			atlasName = "Raid",
		},
		
		{
			journalInstanceID = 1207,		-- Amirdrassil, the Dream's Hope
			x = 0.3000,
			y = 0.5400,
			instanceZone = 2200,				-- Emerals Dream
			atlasName = "Raid",
		},
	},
	
	[2023]={ -- Ohn'ahran Plains
	
		{
			journalInstanceID = 1207,		-- Amirdrassil, the Dream's Hope
			x = 0.1640,
			y = 0.4760,
			instanceZone = 2200,				-- Emerals Dream
			atlasName = "Raid",
		},
	},
	
	[2239]={ -- Amirdrassil
	
		{
			journalInstanceID = 1207,		-- Amirdrassil, the Dream's Hope
			x = 0.1640,
			y = 0.4760,
			instanceZone = 2200,				-- Emerals Dream
			atlasName = "Raid",
		},
	},
	
	----------------------------------------
	--      The War Within Instances      --
	----------------------------------------
	
	[2274]={ -- Kaz Algar
		{
			journalInstanceID = 1272,		-- Cinderbrew Meadery
			x = 0.8500,
			y = 0.2100,
			instanceZone = 2248,				-- Isle of Dorn
			atlasName = "Dungeon",
		},
		
		{
			journalInstanceID = 1268,		-- The Rookery
			x = 0.7000,
			y = 0.1900,
			instanceZone = 2248,				-- Isle of Dorn
			atlasName = "Dungeon",
		},
		
		{
			journalInstanceID = 1296,		-- Liberation of Undermine
			x = 0.8550,
			y = 0.7340,
			instanceZone = 2346,				-- Undermine
			atlasName = "Raid",
		},
		
		{
			journalInstanceID = 1302,		-- Manaforge Omega
			x = 0.1570,
			y = 0.1710,
			instanceZone = 2371,				-- K'aresh
			atlasName = "Raid",
		},
		
		{
			journalInstanceID = 1194,		-- Tazavesh, the Vailed Market
			x = 0.1570,
			y = 0.2240,
			instanceZone = 2371,				-- K'aresh
			atlasName = "Dungeon",
		},
		
		{
			journalInstanceID = 1303,		-- Eco-Dome Al'dani
			x = 0.1980,
			y = 0.2240,
			instanceZone = 2371,				-- K'aresh
			atlasName = "Dungeon",
		},
	},
	
	----------------------------------
	--      Midnight Instances      --
	----------------------------------
	
	[2537]={ -- Quel Talas (Midnight)
		{
			journalInstanceID = 1307,		-- Voidspire
			x = 0.5250,
			y = 0.2700,
			instanceZone = 2405,				-- Voidstorm
			atlasName = "Raid",
		},
		
		{
			journalInstanceID = 1316,		-- Nexus-Point Xenas
			x = 0.5500,
			y = 0.2600,
			instanceZone = 2405,				-- Voidstorm
			atlasName = "Dungeon",
		},
		
		{
			journalInstanceID = 1313,		-- Voidscar Arena
			x = 0.5340,
			y = 0.1910,
			instanceZone = 2405,				-- Voidstorm
			atlasName = "Dungeon",
		},
		
		{
			journalInstanceID = 1314,		-- Dreamrift
			x = 0.8280,
			y = 0.1930,
			instanceZone = 2413,				-- Haranadar
			atlasName = "Raid",
		},
		
		{
			journalInstanceID = 1309,		-- The Blinding Vale
			x = 0.7900,
			y = 0.2000,
			instanceZone = 2413,				-- Haranadar
			atlasName = "Dungeon",
		},
		
		{
			journalInstanceID = 1304,		-- Murder Row
			x = 0.2900,
			y = 0.3740,
			instanceZone = 2393,				-- Silvermoon
			atlasName = "Dungeon",
		},
	},
	
	[2395]={ -- Eversong Woods (Midnight)
		{
			journalInstanceID = 1304,		-- Murder Row
			x = 0.5400,
			y = 0.2445,
			instanceZone = 2393,				-- Silvermoon
			atlasName = "Dungeon",
		},
		
		{
			journalInstanceID = 1315,    -- Maisara Caverns
			x = 0.8188,
			y = 0.6726,
			instanceZone = 2437,    -- Zul'Aman
			atlasName = "Dungeon",
		},
		
	},
	
	
}