local H, C, L = unpack(select(2,...))

C["DRUID"] = {
	predefined = {
		[1] = { spellID = 774 }, -- Rejuvenation
		[2] = { spellID = 2782, dispels = { ["Poison"] = true, ["Curse"] = true } }, -- Remove Corruption
		[3] = { spellID = 5185 }, -- Healing Touch
		[4] = { spellID = 8936 }, -- Regrowth
		[5] = { spellID = 18562, buffs = { 774, 8936 } }, -- Swiftmend, castable only if affected by Rejuvenation or Regrowth
		[6] = { spellID = 20484, rez = true }, -- Rebirth
		[7] = { spellID = 29166 }, -- Innervate
		[8] = { spellID = 33763 }, -- Lifebloom
		[9] = { spellID = 48438 }, -- Wild Growth
		[10] = { spellID = 50464 }, -- Nourish
		[11] = { spellID = 88423, dispels = { ["Poison"] = true, ["Curse"] = true, ["Magic"] = true } }, -- Nature's Cure
		[12] = { spellID = 102351 }, -- Cenarion Ward [Talent]
		[13] = { spellID = 102342 }, -- Ironbark
	},
	[3] = { -- Guardian
		spells = {
			{ id = 12 },
			{ id = 2 },
		},
	},
	[4] = { -- Restoration
		buffs = {
			102352, -- Cenarion Ward heal buff
		},
		spells = {
			{ id = 1 },
			{ id = 8 },
			{ id = 10 },
			{ id = 4 },
			{ id = 5 },
			{ id = 3 },
			{ id = 9 },
			{ id = 12 },
			{ id = 13 },
			{ id = 11 },
			{ id = 6 },
		},
	}
}