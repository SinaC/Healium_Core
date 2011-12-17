--if true then return end

--\FrameXML\ActionButton.lua:366 overlay glow stuff
--SPELL_ACTIVATION_OVERLAY_GLOW_SHOW
--SPELL_ACTIVATION_OVERLAY_GLOW_HIDE

--ActionBarButtonSpellActivationAlert
--http://canlite.googlecode.com/svn-history/r258/trunk/AddOns/NugRunning/NugRunning.lua search on SPELL_ACTIVATION_OVERLAY_GLOW_SHOW
--http://www.wowinterface.com/downloads/info10440-NugRunning.html

local _, class = UnitClass("player")
if class ~= "SHAMAN" and class ~= "PRIEST" then return end

local function DumpButton(button)
	for key, value in pairs(button) do
		print(tostring(key).."->"..tostring(value))
	end
end

local function DumpAction()
	-- Prints all types and subtypes found in the player's actions
	local types = {}
	for i=1,120 do
	   local type,id,subtype = GetActionInfo(i)
	   if type then
		  types[type] = types[type] or {}
		  if subtype then
			 types[type][subtype] = 1
		  end
	   end
	end
	 
	for type, subtypes in pairs(types) do
	   print("Type:", type, "subtypes:")
	   local numSubtypes = 0
	   for subtype in pairs(subtypes) do
		  print("   ", subtype)
		  numSubtypes = numSubtypes + 1
	   end
	 
	   if numSubtypes == 0 then
		  print("   no subtypes")
	   end
	end
end

local function GetSpellBookID(spellName)
	for i = 1, 300, 1 do
		local spellBookName = GetSpellBookItemName(i, BOOKTYPE_SPELL)
		if not spellBookName then break end
		if spellName == spellBookName then
			-- local slotType = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
			-- if slotType == "SPELL" then
				return i
			-- end
			-- return nil
		end
	end
	return nil
end

local testFrame = CreateFrame("Frame")
-- testFrame:RegisterEvent("PLAYER_LOGIN")
-- testFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
-- testFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
-- testFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
-- testFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_SHOW")
-- testFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_HIDE")
testFrame:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, ...)
	if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
		print("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW:"..tostring(arg1))
	elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
		print("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE:"..tostring(arg1))
	elseif event == "SPELL_ACTIVATION_OVERLAY_SHOW" then
		print("SPELL_ACTIVATION_OVERLAY_SHOW:"..tostring(arg1))
	elseif event == "SPELL_ACTIVATION_OVERLAY_HIDE" then
		print("SPELL_ACTIVATION_OVERLAY_HIDE:"..tostring(arg1))
	elseif event == "PLAYER_LOGIN" then
--[[
		local button = CreateFrame("Button", "ButtonChastise", UIParent, "SecureActionButtonTemplate")
		button:SetPoint("CENTER", UIParent, "CENTER")
		button:SetSize(32, 32)
		button.texture = button:CreateTexture(nil, "ARTWORK")
		button.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		button.texture:SetPoint("TOPLEFT", button ,"TOPLEFT", 0, 0)
		button.texture:SetPoint("BOTTOMRIGHT", button ,"BOTTOMRIGHT", 0, 0)
		button:SetPushedTexture("Interface/Buttons/UI-Quickslot-Depress")
		button:SetHighlightTexture("Interface/Buttons/ButtonHilight-Square")
		button.cooldown = CreateFrame("Cooldown", "$parentCD", button, "CooldownFrameTemplate")
		button.cooldown:SetAllPoints(button.texture)

		button:SetScript("OnAttributeChanged", function(self, name, value)
			if name == "spell" then
				local spell = self:GetAttribute("spell")
				local icon = spell and GetSpellTexture(spell, BOOKTYPE_SPELL)
print("OnAttributeChanged:"..self:GetName().." "..tostring(name).." "..tostring(value).."  "..tostring(spell).."  "..tostring(icon))
				self.texture:SetTexture(icon)
			end
		end)

		if class == "SHAMAN" then
			button:RegisterForClicks("AnyUp")
			button:SetAttribute("unit", "player")
			button:SetAttribute("*helpbutton1", "heal")
			button:SetAttribute("*type-heal", "spell")
			button:SetAttribute("spell-heal", "Vague de soins")
			button:SetAttribute("ctrl-spell-heal", "Remous")
			button.texture:SetTexture("Interface/Icons/INV_Misc_QuestionMark")
		elseif class == "PRIEST" then
			local spellID = 88625
			local spellName = GetSpellInfo(spellID)
			local bookSpellID = GetSpellBookID(spellName)
			--local overlayed = IsSpellOverlayed(bookSpellID)
print("SPELL:"..tostring(spellID).." "..tostring(spellName).." "..tostring(bookSpellID).." "..tostring(overlayed))

			button:RegisterForClicks("AnyUp")
			button:SetAttribute("unit", "player")
			button:SetAttribute("*unit2", "target")
			button:SetAttribute("type", "spell")
			button:SetAttribute("spell", bookSpellID)
		end

-- http://wiki.ngacn.cc/index.php?title=UI_SecureActionButtonTemplate
--For example, we can define a new "heal" virtual button for all friendly left clicks, 
--and then set the button to cast "Flash Heal" on an unmodified left click and "Renew" on a ctrl left click: 
-- self:SetAttribute("*helpbutton1", "heal");
-- self:SetAttribute("*type-heal", "spell");
-- self:SetAttribute("spell-heal", "Flash Heal");
-- self:SetAttribute("ctrl-spell-heal", "Renew");

		button:Show()

		testFrame.HolyWordChastiseFrame = button
--]]

		-- ActionButton4:HookScript("OnAttributeChanged", function(self, name, value)
			-- print("OnAttributeChanged:"..self:GetName().." "..tostring(name).." "..tostring(value))
		-- end)
		-- ActionButton4:HookScript("OnEvent", function(self, event, arg1, arg2, arg3)
			-- print("OnEvent:"..self:GetName().." "..tostring(event).." "..tostring(arg1).." "..tostring(arg2).." "..tostring(arg3))
		-- end)

		-- ActionButton4Panel:HookScript("OnAttributeChanged", function(self, name, value)
			-- print("OnAttributeChanged:"..self:GetName().." "..tostring(name).." "..tostring(value))
		-- end)
		-- TukuiBar1:HookScript("OnAttributeChanged", function(self, name, value)
			-- print("OnAttributeChanged:"..self:GetName().." "..tostring(name).." "..tostring(value))
		-- end)
		-- TukuiBar4:HookScript("OnAttributeChanged", function(self, name, value)
			-- print("OnAttributeChanged:"..self:GetName().." "..tostring(name).." "..tostring(value))
		-- end)
		--DumpButton(ActionButton4)
		--DumpActions()
	elseif event == "SPELL_UPDATE_COOLDOWN" then
--[[
		local spellID = 88625
		local spellName = GetSpellInfo(spellID)
		local bookSpellID = GetSpellBookID(spellName)
		-- local overlayed = IsSpellOverlayed(bookSpellID)
-- print("SPELL:"..tostring(spellID).." "..tostring(spellName).." "..tostring(bookSpellID).." "..tostring(overlayed))

		local start, duration, enabled = GetSpellCooldown(spellName)
		if start and duration then
			CooldownFrame_SetTimer(testFrame.HolyWordChastiseFrame.cooldown, start, duration, enabled)
		end
		--]]
	end
end)