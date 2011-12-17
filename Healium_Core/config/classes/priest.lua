local H, C, L = unpack(select(2,...))

C["PRIEST"] = {
	predefined = {
		[1] = { spellID = 17, debuffs = { 6788 } }, -- Power Word: Shield not castable if affected by Weakened Soul (6788)
		[2] = { spellID = 139 }, -- Renew
		[3] = { spellID = 527, dispels = { ["Magic"] = true } }, -- Dispel Magic (Discipline, Holy)
		[4] = { spellID = 528, dispels = { ["Disease"] = true } }, -- Cure Disease
		[5] = { spellID = 596 }, -- Prayer of Healing
		[6] = { spellID = 1706 }, -- Levitate
		[7] = { spellID = 2050 }, -- Heal
		[8] = { spellID = 2060 }, -- Greater Heal
		[9] = { spellID = 2061 }, -- Flash Heal
		[10] = { spellID = 6346 }, -- Fear Ward
		[11] = { spellID = 32546 }, -- Binding Heal
		[12] = { spellID = 33076 }, -- Prayer of Mending
		[13] = { spellID = 33206 }, -- Pain Suppression (Discipline)
		[14] = { spellID = 34861 }, -- Circle of Healing (Holy)
		[15] = { spellID = 47540 }, -- Penance (Discipline)
		[16] = { spellID = 47788 }, -- Guardian Spirit (Holy)
		[17] = { spellID = 73325 }, -- Leap of Faith
		[18] = { spellID = 88625, transforms = { [81206] = { spellID = 88685 }, [81208] = { spellID = 88684 } } }, -- Holy Word: Chastise (transformed in Holy Word: Sanctuary(88685) if affected by Chakra: Sanctuary(81206) or in Holy Word: Serenity(88684) if affected by Chakra: Serenity(81208)
		[19] = { spellID = 10060 }, -- Power Infusion (Discipline)
	},
	[1] = { -- Discipline
		spells = {
			{ id = 1 },
			{ id = 2 },
			{ id = 9 },
			{ id = 7 },
			{ id = 8 },
			{ id = 15 },
			{ id = 13 },
			{ id = 12 },
			{ id = 5 },
			{ id = 3 },
			{ id = 4 },
		},
	},
	[2] = { -- Holy
		spells = { 
			{ id = 2 },
			{ id = 9 },
			{ id = 7 },
			{ id = 8 },
			{ id = 18 },
			{ id = 12 },
			{ id = 14 },
			{ id = 5 },
			{ id = 16 },
			{ id = 3 },
			{ id = 4 }
		}
	}
}