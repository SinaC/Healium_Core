local H, C, L = unpack(select(2,...))

-- list of shield debuff/buff -> display an additional information on icon with total heal/damage received/taken
C["shields"] = {
	-- if not amount specified, increasing value
	-- if amount specified, decreasing value starting at amount
	[105479] = {type = "DEBUFF", modifier = "HEAL", amount = 200000, map = 824}, -- Searing Plasma (Spine of Deathwing 10N)
	[109362] = {type = "DEBUFF", modifier = "HEAL", amount = 300000, map = 824}, -- Searing Plasma (Spine of Deathwing 25N)
	[109363] = {type = "DEBUFF", modifier = "HEAL", amount = 280000, map = 824}, -- Searing Plasma (Spine of Deathwing 10H)
	[109364] = {type = "DEBUFF", modifier = "HEAL", amount = 420000, map = 824}, -- Searing Plasma (Spine of Deathwing 25H)

	-- TEST
	-- [974] = {type = "BUFF", modifier = "HEAL" }, -- Earth shield TODO remove
	-- [57724] = {type = "DEBUFF", modifier = "HEAL", amount = 100000 }, -- Bloodlust TODO remove
	--[53563] = {type = "BUFF", modifier = "HEAL", amount = 200000}--, map = 4  }, -- Guide de lumière + Durotar
}