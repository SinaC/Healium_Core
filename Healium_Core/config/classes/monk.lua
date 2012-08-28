local H, C, L = unpack(select(2,...))

C["MONK"] = {
	predefined = {
		[1] = { spellID = 115098 }, -- Chi Wave
		[2] = { spellID = 115151 }, -- Renewing Mist
		[3] = { spellID = 115175 }, -- Soothing Mist
		[4] = { spellID = 115450, dispels = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = true } }, -- Detox
		[5] = { spellID = 116694 }, -- Surging Mist
		[6] = { spellID = 116849 }, -- Life Cocoon
		[7] = { spellID = 124682 }, -- Enveloping Mist
	},
}