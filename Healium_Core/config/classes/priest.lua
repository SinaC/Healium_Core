local H, C, L = unpack(select(2,...))

C["PRIEST"] = {
	predefined = {
		[1] = { spellID = 17, debuffs = { 6788 }, display = "value2" }, -- Power Word: Shield not castable if affected by Weakened Soul (6788) TODO: except if caster is affected by Divine Insight
		[2] = { spellID = 139 }, -- Renew
		[3] = { spellID = 527, dispels = { ["Magic"] = true, ["Disease"] = true } }, -- Purify
		[4] = { spellID = 596 }, -- Prayer of Healing
		[5] = { spellID = 1706 }, -- Levitate
		[6] = { spellID = 2061 }, -- Heal
		[7] = { spellID = 2060 }, -- Greater Heal
		[8] = { spellID = 2061 }, -- Flash Heal
		[9] = { spellID = 6346 }, -- Fear Ward
		[10] = { spellID = 32546 }, -- Binding Heal
		[11] = { spellID = 33076 }, -- Prayer of Mending
		[12] = { spellID = 33206 }, -- Pain Suppression (Discipline)
		[13] = { spellID = 34861 }, -- Circle of Healing (Holy)
		[14] = { spellID = 47540 }, -- Penance (Discipline)
		[15] = { spellID = 47788 }, -- Guardian Spirit (Holy)
		[16] = { spellID = 73325 }, -- Leap of Faith
		[17] = { spellID = 88625, transforms = { [81206] = { spellID = 88685 }, [81208] = { spellID = 88684 } } }, -- Holy Word: Chastise (transformed in Holy Word: Sanctuary(88685) if affected by Chakra: Sanctuary(81206) or in Holy Word: Serenity(88684) if affected by Chakra: Serenity(81208)
		[18] = { spellID = 108968 }, -- Void Shift
		[19] = { spellID = 121135 }, -- Cascade
	},
}