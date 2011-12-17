local H, C, L = unpack(select(2,...))

C["SHAMAN"] = {
	predefined = {
		[1] = { spellID = 331 }, -- Healing Wave
		[2] = { spellID = 1064 }, -- Chain Heal
		[3] = { spellID = 974 }, -- Earth Shield
		[4] = { spellID = 8004 }, -- Healing Surge
		[5] = { spellID = 51886, dispels = { ["Curse"] = true, ["Magic"] = function() return select(5, GetTalentInfo(3,12)) > 0 end } }, -- Cleanse Spirit
		[6] = { spellID = 61295 }, -- Riptide
		[7] = { spellID = 77472 },  -- Greater Healing Wave
	},
	[3] = { -- Restoration
		spells = {
			{ id = 3 },
			{ id = 6 },
			{ id = 4 },
			{ id = 1 },
			{ id = 7 },
			{ id = 2 },
			{ id = 5 },
			-- { spellID = 974 }, -- Earth Shield
			-- { spellID = 61295 }, -- Riptide
			-- { spellID = 8004 }, -- Healing Surge
			-- { spellID = 331 }, -- Healing Wave
			-- { spellID = 77472 },  -- Greater Healing Wave
			-- { spellID = 1064 }, -- Chain Heal
			-- { spellID = 51886, dispels = { ["Curse"] = true, ["Magic"] = function() return select(5, GetTalentInfo(3,12)) > 0 end } }, -- Cleanse Spirit
		},
	}
}