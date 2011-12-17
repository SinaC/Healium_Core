local H, C, L = unpack(select(2,...))

C["DRUID"] = {
	predefined = {
		[1] = { spellID = 774 }, -- Rejuvenation
		[2] = { spellID = 2782, dispels = { ["Poison"] = true, ["Curse"] = true, ["Magic"] = function() return select(5, GetTalentInfo(3,17)) > 0 end } }, -- Remove Corruption
		[3] = { spellID = 5185 }, -- Healing Touch
		[4] = { spellID = 8936 }, -- Regrowth
		[5] = { spellID = 18562, buffs = { 774, 8936 } }, -- Swiftmend, castable only if affected by Rejuvenation or Regrowth
		[6] = { spellID = 20484, rez = true }, -- Rebirth
		[7] = { spellID = 29166 }, -- Innervate
		[8] = { spellID = 33763 }, -- Lifebloom
		[9] = { spellID = 48438 }, -- Wild Growth
		[10] = { spellID = 50464 }, -- Nourish
	},
	[3] = { -- Restoration
		spells = {
			{ id = 1 },
			{ id = 8 },
			{ id = 10 },
			{ id = 4 },
			{ id = 5 },
			{ id = 3 },
			{ id = 9 },
			{ id = 2 },
			{ id = 6 },
			-- { spellID = 774 }, -- Rejuvenation
			-- { spellID = 33763 }, -- Lifebloom
			-- { spellID = 50464 }, -- Nourish
			-- { spellID = 8936 }, -- Regrowth
			-- { spellID = 18562, buffs = { 774, 8936 } }, -- Swiftmend, castable only if affected by Rejuvenation or Regrowth
			-- { spellID = 5185 }, -- Healing Touch
			-- { spellID = 48438 }, -- Wild Growth
			-- { spellID = 2782, dispels = { ["Poison"] = true, ["Curse"] = true, ["Magic"] = function() return select(5, GetTalentInfo(3,17)) > 0 end } }, -- Remove Corruption
			-- { spellID = 20484, rez = true }, -- Rebirth
		},
	}
}