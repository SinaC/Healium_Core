local H, C, L = unpack(select(2,...))

C["SHAMAN"] = {
	predefined = {
		[1] = { spellID = 331 }, -- Healing Wave
		[2] = { spellID = 1064 }, -- Chain Heal
		[3] = { spellID = 974 }, -- Earth Shield
		[4] = { spellID = 8004 }, -- Healing Surge
		[5] = { spellID = 51886, dispels = { ["Curse"] = true, ["Magic"] = function() return GetSpecialization() == 3 and UnitLevel("player") >= 20 end } }, -- Cleanse Spirit or Purify Spirit
		[6] = { spellID = 61295 }, -- Riptide
		[7] = { spellID = 77472 },  -- Greater Healing Wave
	},
}