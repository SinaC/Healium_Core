-- Character/Class specific config

local _, ns = ...
local H, C, L = unpack(select(2,...))
local Private = ns.Private

if H.myname == "Meuhhnon" then
	C["general"].debuffFilter = "BLACKLIST"

	C["DRUID"][3].spells[6] = { macroName = "NSHT" } -- Nature Swiftness + Healing Touch
	C["DRUID"][3].spells[9] = { macroName = "NSBR" } -- Nature Swiftness + Rebirth

	-- -- TEST
	-- C["DRUID"][3].buffs = { 33076 } -- Prayer of mending

	-- remove Weakened soul from blacklist(6788)
	if C["blacklist"] then
		--Private.TRemoveByVal(C["blacklist"], 6788)
	end
end

if H.myname == "Enimouchet" then
	C["general"].debuffFilter = "BLACKLIST"

	-- --------------------------------------------------
	-- -- TEST
	-- C.general.buttonSpacing = 0
	-- C.general.buffSpacing = 0
	-- C.general.debuffSpacing = 0
end

if H.myname == "Yoog" then
	C["general"].debuffFilter = "BLACKLIST"

	C["SHAMAN"][3].spells[5] = { macroName = "NSHW" } -- Nature Swiftness + Greater Healing Wave

	--------------------------------------------------
	-- TEST
	C["general"].debuffFilter = "NONE"

	C["general"].debugDebuff = "Curse"

	--C["SHAMAN"][3].spells = nil

	C["general"].showPriorityDebuff = true
	C["SHAMAN"][1] = {}
	C["SHAMAN"][1].spells = {
		{ macroName = "TEST" }
	}
	C["general"].maxButtonCount = 14
	-- C.general.buttonSpacing = 0
	-- C.general.buffSpacing = 0
	-- C.general.debuffSpacing = 0
	C["SHAMAN"][3].spells = {
		{ id = 3 }, -- Earth Shield
		{ id = 6 }, -- Riptide
		{ id = 4 }, -- Healing Surge
		{ id = 1 }, -- Healing Wave
		{ macroName = "NSHW" }, -- Greater Healing Wave
		{ id = 2 }, -- Chain Heal
		{ id = 5 }, -- Cleanse Spirit
		{ id = 6 }, -- Riptide
		{ id = 6 }, -- Riptide
		{ id = 6 }, -- Riptide
		{ id = 6 }, -- Riptide
		{ id = 6 }, -- Riptide
		{ id = 6 }, -- Riptide
		{ id = 6 }, -- Riptide
	}
	-- C["SHAMAN"][3].spells = {
		-- { macroName = "TESTCD" },
		-- { macroName = "TEST" }
	-- }
end

if H.myname == "Nigguro" then
	C["general"].debuffFilter = "BLACKLIST"

	-- remove Weakened soul from blacklist(6788)
	if C["blacklist"] then
		Private.TRemoveByVal(C["blacklist"], 6788)
	end
end

--------------------------------------------------------------

if H.myname == "Holycrap" then
	C["general"].maxButtonCount = 15
	C["general"].dispelAnimation = "NONE"
	C["general"].debuffFilter = "BLACKLIST"

	C["PRIEST"][1].spells = {
		{ id = 13 }, -- Pain Suppression
		{ id =  1 }, -- Power Word: Shield
		{ id = 15 }, -- Penance
		{ id =  2 }, -- Renew
		{ id =  7 }, -- Heal
		{ id =  8 }, -- Greater Heal
		{ id =  9 }, -- Flash Heal
		{ id = 12 }, -- Prayer of Mending
		{ id = 11 }, -- Binding Heal
		{ id =  5 }, -- Prayer of Healing
		{ id =  3 }, -- Dispel Magic
		{ id =  4 }, -- Cure Disease
		{ id = 19 }, -- Power Infusion
		{ id = 17 }, -- Leap of Faith
	}

	C["PRIEST"][2].spells = {
		{ id =  1 }, -- Power Word: Shield
		{ id =  2 }, -- Renew
		{ id =  7 }, -- Heal
		{ id = 12 }, -- Prayer of Mending
		{ id =  9 }, -- Flash Heal
		{ id =  8 }, -- Greater Heal
		{ id = 11 }, -- Binding Heal
		{ id =  5 }, -- Prayer of Healing
		{ id = 14 }, -- Circle of Healing (Holy)
		{ id =  3 }, -- Dispel Magic
		{ id =  4 }, -- Cure Disease
		{ id = 16 }, -- Guardian Spirit (Holy)
		{ id = 17 }, -- Leap of Faith
	}
end

if H.myname == "Boombella" then
	C["general"].debuffFilter = "BLACKLIST"
	C["SHAMAN"][3].spells = {
		{ id = 3 }, -- Earth Shield
		{ id = 6 }, -- Riptide
		{ id = 1 }, -- Healing Wave
		{ id = 7 }, -- Greater Healing Wave
		{ id = 2 }, -- Chain Heal
		{ id = 4 }, -- Healing Surge
		{ id = 5 }, -- Cleanse Spirit
	}
end

--------------------------------------------------------------

if H.myname == "Noctissia" then
	C["general"].debuffFilter = "BLACKLIST"
	C["SHAMAN"][3].spells = {
		{ id = 3 }, -- Earth Shield
		{ id = 6 }, -- Riptide
		{ id = 1 }, -- Healing Wave
		{ macroName = "NSHW" }, -- Nature Swiftness + Greater Healing Wave
		{ id = 2 }, -- Chain Heal
		{ id = 4 }, -- Healing Surge
		{ id = 5 }, -- Cleanse Spirit
	}
end

if H.myclass == "HUNTER" then
	C["general"].showBuff = true
	C["general"].showDebuff = false
	C["general"].showOOM = false
	C["general"].showOOR = false
end