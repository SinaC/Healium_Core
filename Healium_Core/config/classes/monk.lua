local H, C, L = unpack(select(2,...))

C["MONK"] = {
	predefined = {
		[1] = { spellID = 115151 }, -- Renewing Mist
		[2] = { spellID = 115175 }, -- Soothing Mist
		[3] = { spellID = 115450, dispels = { ["Poison"] = true, ["Disease"] = true, ["Magic"] = true } }, -- Detox
		[4] = { spellID = 116694 }, -- Surging Mist
		[5] = { spellID = 116849 }, -- Life Cocoon
		[6] = { spellID = 124682 }, -- Enveloping Mist
	},
	[2] = { -- Mistweaver
		spells = {
			{ id = 1 },
			{ id = 2 },
			{ id = 4 },
			{ id = 6 },
			{ id = 5 },
			{ id = 3 },
		},
	},
}