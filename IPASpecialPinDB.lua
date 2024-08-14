local addonName, IPA = ...


IPAUISpecialPinDB = {

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
			atlasName = "Dungeon",
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
			atlasName = "Dungeon",
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
	},
	
}