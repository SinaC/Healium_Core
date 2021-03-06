local H, C, L = unpack(select(2,...))

C["PALADIN"] = {
	predefined = {
		[1] = { spellID = 633, debuffs = { 25771 } }, -- Lay on Hands (not if affected by Forbearance)
		[2] = { spellID = 82326 }, -- Holy Light
		[3] = { spellID = 1022, debuffs = { 25771 } }, -- Hand of Protection (not if affected by Forbearance)
		[4] = { spellID = 1038 }, -- Hand of Salvation
		[5] = { spellID = 1044 }, -- Hand of Freedom
		[6] = { spellID = 4987, dispels = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = function() return GetSpecialization() == 1 and UnitLevel("player") >= 20 end } }, -- Cleanse    magic only if spell 53551 is known or (holy spec and lvl >= 20)
		[7] = { spellID = 6940 }, -- Hand of Sacrifice
		[8] = { spellID = 19750 }, -- Flash of Light
		[9] = { spellID = 20473 }, -- Holy Shock
		[10] = { spellID = 20925 }, -- Sacred Shield
		[11] = { spellID = 53563 }, -- Beacon of Light
		[12] = { spellID = 82326 }, -- Divine Light
		[13] = { spellID = 82327 }, -- Holy Radiance
		[14] = { spellID = 85673 }, -- Word of Glory
		[15] = { spellID = 114039 }, -- Hand of Purity
		[16] = { spellID = 114157 }, -- Execution Sentence
		[17] = { spellID = 114165 }, -- Holy Prism
		[18] = { spellID = 114163 }, -- Eternal Flame
	},
}