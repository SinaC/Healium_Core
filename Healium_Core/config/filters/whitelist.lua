local H, C, L = unpack(select(2,...))

-- spellID  or {spellID, priority}     priority: lower value -> higher priority
-- no priority -> 1000 (lowest priority)
C["whitelist"] = {
-- PVE
------
--MISC
	{67479, 10},	-- Impale
--CATA DEBUFFS
	--Baradin Hold {752] -- Baradin Hold 
	{95173, 9},	-- Consuming Darkness
	{88942, 9},	-- Meteor Slash (Argaloth)

--Blackwing Descent {754] -- Blackwing Descent 
	--Magmaw
	{91911, 6},	-- Constricting Chains
	{94679, 6},	-- Parasitic Infection
	{94617, 7},	-- Mangle
	{91923, 7},	-- Infectious Vomit
	--Omnitron Defense System
	{79835, 6},	-- Poison Soaked Shell
	{91433, 9},	-- Lightning Conductor
	{91521, 6},	-- Incineration Security Measure
	{92048, 7},	-- Shadow Infusion
	{79505, 7},	-- Flamethrower
	{80161, 8},	-- Chemical Cloud
	{79501, 7},	-- Acquiring Target
	{80011, 8},	-- Soaked in Poison
	{80094, 8},	-- Fixate
	{92023, 6},	-- Encasing Shadows
	{92053, 6},	-- Shadow Conductor
	--Maloriak
	{77699, 7},	-- Flash Freeze
	{77786, 7},	-- Consuming Flames
	{77760, 8},	-- Biting Chill
	{91829, 8},	-- Fixate
	{92787, 6},	-- Engulfing Darkness
	--Atramedes
	{92423, 7},	-- Searing Flame
	{92485, 8},	-- Roaring Flame
	{92407, 9},	-- Sonic Breath
	{78092, 8},	-- Tracking
	{78897, 7},	-- Noisy
	--Chimaeron
	{82881, 8},	-- Break
	{82705, 10},	-- Finkle's Mixture
	{89084, 7},	-- Low Health
	{82890, 9},	-- Mortality
	--Nefarian
	{92053, 9},	-- Shadow Conductor
	{94128, 8},	-- Tail Lash
	{79339, 6},	-- Explosive Cinders
	{79318, 6},	-- Dominion

--The Bastion of Twilight
	--Halfus Wyrmbreaker
	{39171, 8},	-- Malevolent Strikes
	{86169, 8},	-- Furious Roar

	--Valiona & Theralion
	{92878, 9},	-- Blackout
	86840,		-- Devouring Flames
	{95639, 8},	-- Engulfing Magic
	92861,		-- Twilight Meteorite
	{86202, 8},	-- Twilight Shift

	--Twilight Ascendant Council
	92511,	-- Hydro Lance
	{82762, 8},	-- Waterlogged
	92505,		-- Frozen
	92518,		-- Flame Torrent
	{83099, 8},	-- Lightning Rod
	92075,		-- Gravity Core
	92488,		-- Gravity Crush
	{82662, 8},	-- Burning Blood
	{82667, 8},	-- Heart of Ice
	83500,		-- Swirling Winds
	83587,		-- Magnetic Pull
	{82285, 7},	-- Elemental Stasis
	{92488, 8},	-- Gravity Crush

	--Cho'gall
	{86028, 9},	-- Cho's Blast
	{86029, 9},	-- Gall's Blast
	{81836, 7},	-- Corruption: Accelerated
	{82125, 7},	-- Corruption: Malformation
	{82170, 7},	-- Corruption: Absolute
	{93200, 7},	-- Corruption: Sickness
	{93189, 8}, -- Corrupted Blood
	{93133, 8}, -- Debilitating Beam

	--Sinestra
	{92956, 6},	--Wrack

--Throne of the Four Winds {773] -- Throne of the Four Winds 
	--Conclave of Wind
	{93123, 8},	-- Wind Chill
		--Nezir <Lord of the North Wind>
		{93131, 8},	--Ice Patch
		--Anshal <Lord of the West Wind>
		{86206, 8},	--Soothing Breeze
		{93122, 7},	--Toxic Spores
		--Rohash <Lord of the East Wind>
		{93058, 8},	--Slicing Gale

		{86481, 8},	-- Hurricane
		{85576, 9},	-- Withering Winds
		{85573, 9},	-- Deafening Winds
	--Al'Akir
	{87873, 8},	-- Static Shock
	93260,		-- Ice Storm
	{93295, 7},	-- Lightning Rod
	{93279, 8},	-- Acid Rain
	{88427, 8},	-- Electrocute
	{93284, 6},	-- Squall Line

-- Firelands, thanks Kaelhan :)  {800] -- Firelands 
	-- Beth'tilac
		99506,	-- Widows Kiss
		97202,	-- Fiery Web Spin
		49026,	-- Fixate
		97079,	-- Seeping Venom
	-- Lord Rhyolith
		98492,	-- Eruption
	-- Alysrazor
		101296,	-- Fieroblast
		100723,	-- Gushing Wound
		99389,	-- Imprinted
		101729,	-- Blazing Claw
		99461,	-- Blazing Power
		100029,	-- Alysra's Razor
	-- Shannox
		99840,	-- Magma Rupture
		99837,	-- Crystal Prison
		99936,	-- Jagged Tear
	-- Baleroc
		99256,	-- Torment
		99252,	-- Blaze of Glory
		99516,	-- Countdown
		99257,	-- Tormented
	-- Majordomo Staghelm
		98450,	-- Searing Seeds
		98451,	-- Burning Orbs
	-- Ragnaros
		99399,	-- Burning Wound
		100293,	-- Lava Wave
		98313,	-- Magma Blast
		100675,	-- Dreadflame
		100460,	-- Blazing Heat
-- PVP
------
-- Death Knight
	47481,	-- Gnaw (Ghoul)
	47476,	-- Strangulate
	45524,	-- Chains of Ice
	55741,	-- Desecration (no duration, lasts as long as you stand in it)
	58617,	-- Glyph of Heart Strike
	49203,	-- Hungering Cold
-- Druid
	33786,	-- Cyclone
	2637,	-- Hibernate
	5211,	-- Bash
	22570,	-- Maim
	9005,	-- Pounce
	339,	-- Entangling Roots
	45334,	-- Feral Charge Effect
	58179,	-- Infected Wounds
-- Hunter
	3355,	-- Freezing Trap Effect
	1513,	-- Scare Beast
	19503,	-- Scatter Shot
	50541,	-- Snatch (Bird of Prey)
	34490,	-- Silencing Shot
	24394,	-- Intimidation
	50519,	-- Sonic Blast (Bat)
	50518,	-- Ravage (Ravager)
	35101,	-- Concussive Barrage
	5116,	-- Concussive Shot
	13810,	-- Frost Trap Aura
	61394,	-- Glyph of Freezing Trap
	2974,	-- Wing Clip
	19306,	-- Counterattack
	19185,	-- Entrapment
	50245,	-- Pin (Crab)
	54706,	-- Venom Web Spray (Silithid)
	4167,	-- Web (Spider)
	92380,	-- Froststorm Breath (Chimera)
	50271,	-- Tendon Rip (Hyena)
-- Mage
	31661,	-- Dragon's Breath
	118,	-- Polymorph
	18469,	-- Silenced - Improved Counterspell
	44572,	-- Deep Freeze
	33395,	-- Freeze (Water Elemental)
	122,	-- Frost Nova
	55080,	-- Shattered Barrier
	6136,	-- Chilled
	120,	-- Cone of Cold
	31589,	-- Slow
-- Paladin
	20066,	-- Repentance
	10326,	-- Turn Evil
	63529,	-- Shield of the Templar
	853,	-- Hammer of Justice
	2812,	-- Holy Wrath
	20170,	-- Stun (Seal of Justice proc)
	31935,	-- Avenger's Shield
-- Priest
	64058,	-- Psychic Horror
	605,	-- Mind Control
	64044,	-- Psychic Horror
	8122,	-- Psychic Scream
	15487,	-- Silence
	15407,	-- Mind Flay
-- Rogue
	51722,	-- Dismantle
	2094,	-- Blind
	1776,	-- Gouge
	6770,	-- Sap
	1330,	-- Garrote - Silence
	18425,	-- Silenced - Improved Kick
	1833,	-- Cheap Shot
	408,	-- Kidney Shot
	31125,	-- Blade Twisting
	3409,	-- Crippling Poison
	26679,	-- Deadly Throw
-- Shaman
	51514,	-- Hex
	64695,	-- Earthgrab
	63685,	-- Freeze
	39796,	-- Stoneclaw Stun
	3600,	-- Earthbind
	8056,	-- Frost Shock
-- Warlock
	710,	-- Banish
	6789,	-- Death Coil
	5782,	-- Fear
	5484,	-- Howl of Terror
	6358,	-- Seduction (Succubus)
	24259,	-- Spell Lock (Felhunter)
	30283,	-- Shadowfury
	30153,	-- Intercept (Felguard)
	18118,	-- Aftermath
	18223,	-- Curse of Exhaustion
-- Warrior
	20511,	-- Intimidating Shout
	676,	-- Disarm
	18498,	-- Silenced (Gag Order)
	7922,	-- Charge Stun
	12809,	-- Concussion Blow
	20253,	-- Intercept
	46968,	-- Shockwave
	58373,	-- Glyph of Hamstring
	23694,	-- Improved Hamstring
	1715,	-- Hamstring
	12323,	-- Piercing Howl
-- Racials
	20549,	-- War Stomp
}