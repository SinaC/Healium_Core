local H, C, L = unpack(select(2,...))

C["MONK"] = {
	predefined = {
		--[1] = { spellID = 115098 }, -- Chi Wave
		[1] = { spellID = 115151 }, -- Renewing Mist
		[2] = { spellID = 115175 }, -- Soothing Mist
		[3] = { spellID = 115450, dispels = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = function() return GetSpecialization() == 2 and UnitLevel("player") >= 20 end } }, -- Detox
		[4] = { spellID = 116694 }, -- Surging Mist
		[5] = { spellID = 116849 }, -- Life Cocoon
		[6] = { spellID = 124682 }, -- Enveloping Mist
	},
}