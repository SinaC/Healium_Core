local H, C, L = unpack(select(2,...))

C["PALADIN"] = {
	predefined = {
		[1] = { spellID = 633, debuffs = { 25771 } }, -- Lay on Hands (not if affected by Forbearance)
		[2] = { spellID = 635 }, -- Holy Light
		[3] = { spellID = 1022, debuffs = { 25771 } }, -- Hand of Protection (not if affected by Forbearance)
		[4] = { spellID = 1044 }, -- Hand of Freedom
		[5] = { spellID = 1038 }, -- Hand of Salvation
		--[6] = { spellID = 4987, dispels = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = function() return select(5, GetTalentInfo(1,14)) > 0 end } }, -- Cleanse
		[6] = { spellID = 4987, dispels = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = true } }, -- Cleanse
		[7] = { spellID = 6940 }, -- Hand of Sacrifice
		[8] = { spellID = 19750 }, -- Flash of Light
		[9] = { spellID = 20473 }, -- Holy Shock
		[10] = { spellID = 31789 }, -- Righteous Defense
		[11] = { spellID = 53563 }, -- Beacon of Light
		[12] = { spellID = 82326 }, -- Divine Light
		[13] = { spellID = 82327 }, -- Holy Radiance
		[14] = { spellID = 85673 }, -- Word of Glory
	},
	[1] = { -- Holy
		spells = {
			{ id = 9 },
			{ id = 14 },
			{ id = 8 },
			{ id = 2 },
			{ id = 12 },
			{ id = 13 },
			{ id = 1 },
			{ id = 3 },
			{ id = 4 },
			{ id = 7 },
			{ id = 6 },
			{ id = 11 },
		}
	},
	[2] = { -- Protection
		spells = {
			{ id = 10 },
			{ id = 7 },
			{ id = 1 },
			{ id = 3 },
			{ id = 6 },
		}
	},
}