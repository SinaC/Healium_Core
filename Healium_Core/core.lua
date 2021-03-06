-------------------------------------------------------
-- Healium
-------------------------------------------------------

-- TODO:
-- move filters in Tukui_Healium

-- Exported functions
----------------------
-- H:Initialize(config)
--	initialize Healium and merge config parameter with own config
-- H:Enable()
--	register events
-- H:Disable()
--	unregister events
-- H:RegisterStyle(styleName, style)
--	register a frame style
-- H:RegisterFrame(frame, styleName)
--	register a frame in Healium
-- H:RegisterSpellList(name, spellList [, buffList])
--	register a triplet name+spellList+buffList (perform a DeepCopy), returns false if modifying current spell list while in combat
-- H:ActivateSpellList(name)
--	activate a registered spell list, returns false if in combat
-- H:DumpInformation()
--	return a table with every available informations about frames/buttons/buffs/debuffs
--[[
H:GetButton(frame, index | "FIRST" | "LAST")
	return index'th, first or last visible button
H:GetBuff(frame, index | "FIRST" | "LAST")
	return index'th, first or last visible buff
H:GetDebuff(frame, index | "FIRST" | "LAST")
	return index'th, first or last visible debuff
--]]

-- Styles
----------------------
-- SkinButton [optional]
--	function to skin a button, parameters: frame, button
-- SkinDebuff [optional]
--	function to skin a debuff, parameters: frame, debuff
-- SkinBuff [optional]
--	function to skin a buff, parameters: frame, buff
-- AnchorButton [optional] default anchoring: right of frame
--	function to anchor a button, parameters: frame, button, buttonList, index
-- AnchorDebuff [optional] default anchoring: right of last visible button
--	function to anchor a debuff, parameters: frame, button, debuffList, index
-- AnchorBuff [optional] default anchoring: left of frame
--	function to anchor a buff, parameters: frame, button, buffList, index
-- PriorityDebuff
--	true if only one priority debuff instead of maxDebuffCount debuffs, false otherwise

local ADDON_NAME, ns = ...
local H, C, L = unpack(select(2,...))

-- Aliases
local Private = ns.Private
local FlashFrame = H.FlashFrame
local PerformanceCounter = H.PerformanceCounter
local ipairs = ipairs
local pairs = pairs
local type = type
local select = select
local next = next

-- Default button color
local OriginButtonVertexColor = {1, 1, 1} -- default value
local OriginButtonBackdropColor = {0.6, 0.6, 0.6} -- default value
local OriginButtonBackdropBorderColor = {0.1, 0.1, 0.1} -- default value

--
local UpdateDelay = 0.2
local HealiumInitialized = false
local HealiumEnabled = false

local SpellListCache = {} -- List of available spellList, CurrentSpellList points to this list
-- local CurrentSpellList = {
	-- spells = nil, -- List of spells
	-- buffs = nil, -- List of buffs to monitor not related to a spell in spells
	-- hasBuffPrereq = false,
	-- hasDebuffPrereq = false,
	-- hasTransforms = false,
-- }
--local SpecSettings = nil
local ButtonHeaders = {} -- List of header for button, store ptr to SpellList, hSpellID, hSpellName, hMacroName, hOOM, ...
--local BuffList = nil -- List of buffs to monitor not related to a spell in ButtonHeaders
--local SpellList = nil -- List of spells in current config
local CurrentSpellListName = nil -- name of current spell list
local CurrentSpellList = nil -- current spell list (ptr to SpellListCache)

local EventsHandler = CreateFrame("Frame")

-- Fields added to unitframe
--		hStyle: style name
--		hDisabled: true if unitframe is dead/ghost/disconnected, false otherwise
--		hButtons: heal buttons (SecureActionButtonTemplate)
--		hDebuffs: debuff on unit (no template)
--		hBuffs: buffs on unit (only buff castable by heal buttons)
----		hUnit: last unit assigned to unitframe (used to avoid looping with player->nil in OnAttributeChanged)
--		hShields: shields on unit (dynamically linked to buff/debuff)
-- Fields added to hButton
--		hHeaderIndex: index in ButtonHeaders table
--		hPrereqFailed: button is disabled because of prereq
--		hNotUsable: not usable (see http://www.wowwiki.com/API_IsUsableSpell)  -> NOT YET USED
--		hDispelHighlight: debuff dispellable by button
--		hOOR: unit of range
-- Fields added to spellSetting (unmodified when a spell is transformed)
--		spellName: added in InitializeSettings
--		spellIcon: added in InitializeSettings
--		transforms.spellName: added in InitializeSettings
-- ButtonHeader fields (contains only valid spell/macro)
--		hSpell: ptr to spell setting from SpecSetting
--		hOOM: true if 'player' has enough mana to cast the spell (replace cacheOOM)
--		hType: "SPELL" or "MACRO", used to set button type attribute
--		hIcon: current button texture (updated when transformed)
--		hSpellID: current spellID (updated when transformed, replace cacheTransform)
--		hSpellName: current spellName (updated when transformed, replace cacheTransform)
--		hMacroName: macro name if button is a macro

-- Aliases for Private functions
local ERROR = Private.ERROR
local WARNING = Private.WARNING
local INFO = Private.INFO
local DEBUG = Private.DEBUG
local GetSpellBookID = Private.GetSpellBookID
--local GetSkillType = Private.GetSkillType
local GetSpellID = Private.GetSpellID
local IsSpellKnown = Private.IsSpellKnown
local DeepCopy = Private.DeepCopy

--[[
-------------------------------------------------------
-- Exposed Getters
-------------------------------------------------------
function H:GetButton(frame, index)
	if not frame.hButtons then return end
	if type(index) == "number" then
		local button = frame.hButtons[index]
		if button and button:IsShown() then return button end
	elseif type(index) == "string" then
		if index == "FIRST" then
			local button = frame.hButtons[1]
			if button and button:IsShown() then return button end
		elseif index == "LAST" then
			for i = #frame.hButtons, 1, -1 do
				local button = frame.hButtons[i]
				if button and button:IsShown() then return button end
			end
		end
	end
end

function H:GetBuff(frame, index)
	if not frame.hBuffs then return end
	if type(index) == "number" then
		local buff = frame.hBuffs[index]
		if buff and buff:IsShown() then return buff end
	elseif type(index) == "string" then
		if index == "FIRST" then
			local buff = frame.hBuffs[1]
			if buff and buff:IsShown() then return buff end
		elseif index == "LAST" then
			for i = #frame.hBuffs, 1, -1 do
				local buff = frame.hBuffs[i]
				if buff and buff:IsShown() then return buff end
			end
		end
	end
end

function H:GetDebuff(frame, index)
	if not frame.hDebuffs then return end
	if type(index) == "number" then
		local debuff = frame.hDebuffs[index]
		if debuff and debuff:IsShown() then return debuff end
	elseif type(index) == "string" then
		if index == "FIRST" then
			local debuff = frame.hDebuffs[1]
			if debuff and debuff:IsShown() then return debuff end
		elseif index == "LAST" then
			for i = #frame.hDebuffs, 1, -1 do
				local debuff = frame.hdebuffs[i]
				if debuff and debuff:IsShown() then return debuff end
			end
		end
	end
end
--]]

-------------------------------------------------------
-- Helpers
-------------------------------------------------------
-- Return spellID, spellName, macroName, icon, OOM, spellSetting
local function GetButtonSpellInfo(button)
	if not button.hHeaderIndex or button.hHeaderIndex == 0 then return end
	local header = ButtonHeaders[button.hHeaderIndex]
	if not header then return end
	return header.hSpellID, header.hSpellName, header.hMacroName, header.hIcon, header.hOOM, header.hSpell
end

local function FormatShieldValue(value, maxValue)
	value = value or 0
	-- if maxValue then  -- PERCENTAGE
		-- return string.format("%d%%", math.max(1, math.floor(100 * value / maxValue)))
	-- else
		if value >= 1000000 then
			return string.format("%.1fm", value/1000000)
		elseif value >= 1000 then
			return string.format("%dk", value/1000)
		else
			return value
		end
	-- end
end

-------------------------------------------------------
-- Styles list management
-------------------------------------------------------
local Styles = {}
function H:RegisterStyle(styleName, style)
	Styles[styleName] = style
end

-------------------------------------------------------
-- Unitframes list management
-------------------------------------------------------
local Unitframes = {}
--local UnitframesByUnit = {}

-- -- Unit management  doesn't work: unit is nil when calling this from SaveUnitframe and UnitframeOnAttributeChanged is not called when switching from nil to a real value
-- local function SaveUnitframesByUnit(frame, unit)
-- print("SaveUnitframesByUnit:"..tostring(frame:GetName()).."  "..tostring(unit))
	-- if not unit then return end
	-- if not UnitframesByUnit[unit] then UnitframesByUnit[unit] = {} end
	-- for i, unitframe in ipairs(UnitframesByUnit[unit]) do
		-- if frame == unitframe then
-- print("already in list")
			-- break -- already in list
		-- end
	-- end
-- print("insert new entry")
	-- tinsert(UnitframesByUnit[unit], frame)
	-- frame.hUnit = unit
-- end

-- local function UnitframeOnAttributeChanged(self, name, value)
-- print("UnitframeOnAttributeChanged:"..tostring(self:GetName()).."  "..tostring(name).."  "..tostring(value))
	-- if name == "unit" or name == "unitsuffix" then
		-- local newUnit = SecureButton_GetUnit(self)
		-- local oldUnit = self.hUnit--self.unit
-- print(tostring(newUnit).."  "..tostring(oldUnit))
		-- if newUnit ~= oldUnit then
-- print("UnitframeOnAttributeChanged:"..tostring(oldUnit).."==>"..tostring(newUnit))
			-- -- remove from old UnitframesByUnit list
			-- if oldUnit and UnitframesByUnit[oldUnit] then
				-- for i, unitframe in ipairs(UnitframesByUnit[oldUnit]) do
					-- if unitframe == self then
						-- tremove(UnitframesByUnit[oldUnit], i)
						-- break
					-- end
				-- end
			-- end
			-- -- add to new UnitframesByUnit list
			-- if newUnit then
				-- SaveUnitframesByUnit(self, newUnit)
			-- end
		-- end
		-- self.hUnit = newUnit
	-- end
-- end

-- Loop among every valid with specified GUID in party/raid and call a function
local function ForEachUnitframeWithGUID(GUID, fct, ...)
	--PerformanceCounter:Increment(ADDON_NAME, "ForEachUnitframeWithGUID")
	if not Unitframes then return end
	for _, frame in ipairs(Unitframes) do
		if frame and frame.unit and frame:GetParent():IsShown() then -- frame:IsShown() is false if /reloadui
			local unitGUID = UnitGUID(frame.unit)
			if unitGUID == nil then
				ERROR(string.format(L.GUID_ISNIL, frame.unit))
			elseif GUID == unitGUID then
				fct(frame, ...)
			end
		end
	end
end

-- Loop among every valid with specified unit unitframe in party/raid and call a function
local function ForEachUnitframeWithUnit(unit, fct, ...)
	--PerformanceCounter:Increment(ADDON_NAME, "ForEachUnitframeWithUnit")
	if not Unitframes then return end
	for _, frame in ipairs(Unitframes) do
		--if frame and frame.unit == unit and frame:GetParent():IsShown() then -- frame:IsShown() is false if /reloadui
		if frame and UnitIsUnit(frame.unit, unit) and frame:GetParent():IsShown() then -- frame:IsShown() is false if /reloadui
			fct(frame, ...)
		end
	end
-- --print("ForEachUnitframeWithUnit:"..tostring(unit).."  "..tostring(UnitframesByUnit[unit]))
	-- if not UnitframesByUnit[unit] then return end
	-- for _, frame in ipairs(UnitframesByUnit[unit]) do
-- --print("ForEachUnitframeWithUnit "..unit.."  "..frame:GetName())
		-- if frame and frame:GetParent():IsShown() then
			-- fct(frame, ...)
		-- end
	-- end
end

-- Loop among every valid unitframe in party/raid and call a function
local function ForEachUnitframe(fct, ...)
	--PerformanceCounter:Increment(ADDON_NAME, "ForEachUnitframe")
	if not Unitframes then return end
	for _, frame in ipairs(Unitframes) do
		if frame and frame.unit ~= nil and frame:GetParent():IsShown() then -- frame:IsShown() is false if /reloadui
--print("ForEachUnitframe: VISIBLE "..tostring(frame:GetName()))
			fct(frame, ...)
--		else
--print("ForEachUnitframe: INVISIBLE "..tostring(frame:GetName()).."  "..tostring(frame.unit).."  "..tostring(frame:GetParent():IsShown()))
		end
	end
end

-- Loop among every valid unitframe in party/raid and call a function for each button[index]
local function ForEachUnitframeButton(index, fct, ...)
	--PerformanceCounter:Increment(ADDON_NAME, "ForEachUnitframeButton")
	if not Unitframes then return end
	for _, frame in ipairs(Unitframes) do
		if frame and frame.unit ~= nil and frame:GetParent():IsShown() then -- frame:IsShown() is false if /reloadui
			if frame.hButtons then
				local button = frame.hButtons[index]
				if button then
					fct(frame, button, ...)
				end
			end
		end
	end
end

-- Loop among every unitframe even if not shown or unit is nil
local function ForEachUnitframeEvenIfInvalid(fct, ...)
	--PerformanceCounter:Increment(ADDON_NAME, "ForEachUnitframeEvenIfInvalid")
	if not Unitframes then return end
	for _, frame in ipairs(Unitframes) do
		if frame then
			fct(frame, ...)
		end
	end
end

-- Save frame
local function SaveUnitframe(frame)
	tinsert(Unitframes, frame)
-- print("SaveUnitframe:"..tostring(frame:GetName()).."  "..tostring(frame.unit))
	-- if frame.unit then
		-- SaveUnitframesByUnit(frame, frame.unit)
	-- end
end

-------------------------------------------------------
-- Settings
-------------------------------------------------------

-- Map spellID[, priority] to [spellName] = {spellID[, priority]}
local function CreateFilterList(list, listName)
	local newList = {}
	for key, value in pairs(list) do
		local spellID = type(value) == "table" and value[1] or value
		local priority = type(value) == "table" and value[2] or nil
		local spellName = GetSpellInfo(spellID)
		-- Check if valid and not a duplicate
		if spellName and not newList[spellName] then
			-- Create entry in new list
			if priority then
				newList[spellName] = {spellID = spellID, priority = priority}
			else
				newList[spellName] = {spellID = spellID}
			end
		end
	end
	return newList
end

local function InitializeSettings()
	-- For every class <> myclass, C[class] = nil
	local classList = {"DEATHKNIGHT", "DRUID", "HUNTER", "MAGE", "MONK", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR"}
	for _, class in pairs(classList) do
		if H.myclass ~= class and C[class] then
			C[class] = nil
		end
	end

	-- Fill blacklist, whitelist, dispellable with spellName instead of spellID
	if C.blacklist and C.general.debuffFilter == "BLACKLIST" then
		C.blacklist = CreateFilterList(C.blacklist) -- "debuff blacklist"
	else
		C.blacklist = nil
	end
	if C.whitelist and C.general.debuffFilter == "WHITELIST" then
		C.whitelist = CreateFilterList(C.whitelist) -- "debuff whitelist"
	else
		C.whitelist = nil
	end
	if C.dispellable then
		C.dispellable = CreateFilterList(C.dispellable) -- "dispellable filter"
	end

	-- -- Add spellName to shields
	-- if C.shields then
		-- for spellID, shieldInfo in pairs(C.shields) do
			-- shieldInfo.spellName = GetSpellInfo(spellID)
		-- end
	-- end
end

-------------------------------------------------------
-- Tooltips
-------------------------------------------------------
-- Heal button tooltip
local function ButtonOnEnter(self)
	local tooltipAnchor = C.general.buttonTooltipAnchor or self
	GameTooltip_SetDefaultAnchor(GameTooltip, tooltipAnchor)
	--GameTooltip:SetOwner(tooltipAnchor, "ANCHOR_NONE")
	GameTooltip:ClearLines()
	--local invalid, spellID, spellName, macroName = GetButtonSpellInfo(self)
	local spellID, spellName, macroName = GetButtonSpellInfo(self)
	-- if invalid then
		-- if spellID and spellName then
			-- GameTooltip:AddLine(string.format(L.TOOLTIP_UNKNOWNSPELL, spellName, spellID), 1, 1, 1)
		-- elseif macroName then
			-- GameTooltip:AddLine(string.format(L.TOOLTIP_UNKNOWN_MACRO, macroName), 1, 1, 1)
		-- else
			-- GameTooltip:AddLine(L.TOOLTIP_UNKNOWN, 1, 1, 1)
		-- end
	-- else
		if spellID then
			GameTooltip:SetSpellByID(spellID)
		elseif macroName then
			spellName = GetMacroSpell(macroName)
			if spellName then
				--spellID = GetSpellID(spellName) -- !!! this build a list with a size of 2Mb
				--GameTooltip:SetSpellByID(spellID)
				spellID = GetSpellBookID(spellName) -- Memory optimization
				GameTooltip:SetSpellBookItem(spellID, BOOKTYPE_SPELL)
			end
			GameTooltip:AddLine(string.format(L.TOOLTIP_MACRO, macroName), 1, 1, 1)
		else
			GameTooltip:AddLine(L.TOOLTIP_UNKNOWN, 1, 1, 1)
		end
		local unit = SecureButton_GetUnit(self)
		if not UnitExists(unit) then return end
		local unitName = UnitName(unit)
		if not unitName then unitName = "-" end
		if C.general.debug ~= nil then
			GameTooltip:AddDoubleLine(string.format(L.TOOLTIP_TARGET, unitName), spellID and ("SpellID: "..tostring(spellID)) or "", 1, 1, 1, 1, 1, 1)
		else
			GameTooltip:AddLine(string.format(L.TOOLTIP_TARGET, unitName), 1, 1, 1)
		end
	--end
	GameTooltip:Show()
end

-- Debuff tooltip
local function DebuffOnEnter(self)
	if C.general.debuffTooltipAnchor then
		GameTooltip_SetDefaultAnchor(GameTooltip, C.general.debuffTooltipAnchor)
	else
		--http://wow.go-hero.net/framexml/13164/TargetFrame.xml
		if self:GetCenter() > GetScreenWidth()/2 then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		end
	end
	GameTooltip:SetUnitDebuff(self.unit, self:GetID())
	if IsShiftKeyDown() then
		GameTooltip:AddLine(self.spellID and ("SpellID: "..tostring(self.spellID)) or "", 1, 1, 1, 1, 1, 1)
		INFO("DEBUFF: "..tostring(self.spellName).."("..tostring(self.spellID)..")")
	end
	GameTooltip:Show()
end

-- Buff tooltip
local function BuffOnEnter(self)
	if C.general.buffTooltipAnchor then
		GameTooltip_SetDefaultAnchor(GameTooltip, C.general.buffTooltipAnchor)
	else
		--http://wow.go-hero.net/framexml/13164/TargetFrame.xml
		if self:GetCenter() > GetScreenWidth()/2 then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		else
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		end
	end
	GameTooltip:SetUnitBuff(self.unit, self:GetID())
	if IsShiftKeyDown() then
		GameTooltip:AddLine(self.spellID and ("SpellID: "..tostring(self.spellID)) or "", 1, 1, 1, 1, 1, 1)
		INFO("BUFF: "..tostring(self.spellName).."("..tostring(self.spellID)..")")
	end
	GameTooltip:Show()
end

-------------------------------------------------------
-- Glowing
-------------------------------------------------------
local GlowingSpells = {}
local function AddGlowingSpell(spellID)
	local spellName = GetSpellInfo(spellID)
	if GlowingSpells[spellName] then return end -- already in list
	GlowingSpells[spellName] = true
end

local function RemoveGlowingSpell(spellID)
	local spellName = GetSpellInfo(spellID)
	if not GlowingSpells[spellName] then return end -- not in list
	GlowingSpells[spellName] = nil
end

-------------------------------------------------------
-- Shields
-------------------------------------------------------
--[[
local function IsValidZoneForShields()
	SetMapToCurrentZone()
	local zone = GetCurrentMapAreaID()
	for _, shieldInfo in pairs(C.shields) do
		if not shieldInfo.map then return true end
		if shieldInfo.map and shieldInfo.map == zone then return true end
	end
	return false
end
--]]

-------------------------------------------------------
-- Healium buttons/buffs/debuffs update
-------------------------------------------------------
-- Show button glow
local function ShowButtonGlow(frame, button)
	ActionButton_ShowOverlayGlow(button)
end

-- Hide button glow
local function HideButtonGlow(frame, button)
	ActionButton_HideOverlayGlow(button)
end

-- Update buff icon, id, unit, ...
local function UpdateBuff(frame, buff, id, unit, icon, count, duration, expirationTime, spellID, spellName, displayValue)
	-- id, unit: used by tooltip
	buff:SetID(id)
	buff.unit = unit
	buff.spellID = spellID
	buff.spellName = spellName
	-- texture
	if buff.icon then
		buff.icon:SetTexture(icon)
	end
	-- check shield
	local shieldFound = false
	-- if frame.hShields then
		-- for _, shield in ipairs(frame.hShields) do
			-- if shield.enabled == true and buff.spellID == shield.spellID then
				-- shieldFound = true
			-- end
		-- end
	-- end
	-- count
	if buff.count then
		if count > 1 then
			buff.count:SetText(count)
			buff.count:Show()
		else
			buff.count:Hide()
		end
	end
	-- cooldown
	if buff.cooldown then
		if not shieldFound and duration and duration > 0 then
			local startTime = expirationTime - duration
			--buff.cooldown:SetCooldown(startTime, duration)
			CooldownFrame_SetTimer(buff.cooldown, startTime, duration, true)
			buff.cooldown:Show()
		else
			buff.cooldown:Hide()
		end
	end
	--[[
	-- displayValue
	if buff.shield then
		if displayValue then
			local txt = (type(displayValue) == "number") and FormatShieldValue(displayValue) or tostring(displayValue)
			buff.shield:SetText(txt)
			buff.shield:Show()
print("SHOW BUFF SHIELD: "..tostring(txt))
		end
	end
	--]]
	-- show
	buff:Show()
end

-- Update debuff icon, id, unit, ...
local function UpdateDebuff(frame, debuff, id, unit, icon, count, duration, expirationTime, debuffType, spellID, spellName)
	-- id, unit: used by tooltip
	debuff:SetID(id)
	debuff.unit = unit
	debuff.spellID = spellID
	debuff.spellName = spellName
	-- texture
	if debuff.icon then
		debuff.icon:SetTexture(icon)
	end
	-- check shield
	local shieldFound = false
	-- if frame.hShields then
		-- for _, shield in ipairs(frame.hShields) do
			-- if shield.enabled == true and debuff.spellID == shield.spellID then
				-- shieldFound = true
			-- end
		-- end
	-- end
	-- count
	if debuff.count then
		if count > 1 then
			debuff.count:SetText(count)
			debuff.count:Show()
		else
			debuff.count:Hide()
		end
	end
	-- cooldown
	if debuff.cooldown then
		if not shieldFound and duration and duration > 0 then
			local startTime = expirationTime - duration
			--debuff.cooldown:SetCooldown(startTime, duration)
			CooldownFrame_SetTimer(debuff.cooldown, startTime, duration, true)
			debuff.cooldown:Show()
		else
			debuff.cooldown:Hide()
		end
	end
	-- debuff color
	local debuffColor = debuffType and DebuffTypeColor[debuffType] or DebuffTypeColor["none"]
	debuff:SetBackdropBorderColor(debuffColor.r, debuffColor.g, debuffColor.b)
	-- show
	debuff:Show()
end

-- Update healium button icon
local function UpdateButtonIcon(frame, button, buttonHeader)
	--PerformanceCounter:Increment(ADDON_NAME, "UpdateButtonIcon")
	button.texture:SetTexture(buttonHeader.hIcon)
end

-- Update healium button color depending on frame status and button status
-- frame disabled -> color in dark red except rez spell if dead or ghost
-- out of range -> color in deep red
-- disabled -> dark gray
-- not usable -> color in medium red
-- out of mana -> color in medium blue
-- dispel highlight -> color in debuff color
local function UpdateButtonColor(frame, button)
	--PerformanceCounter:Increment(ADDON_NAME, "UpdateButtonColor")
	local unit = frame.unit
	--local invalid, _, _, _, _, OOM, spellSetting = GetButtonSpellInfo(button)
	local _, _, _, _, OOM, spellSetting = GetButtonSpellInfo(button)

	--TODO: macro

	if frame.hDisabled and (not UnitIsConnected(unit) or not spellSetting or ((not spellSetting.rez or spellSetting.rez == false) and UnitIsDeadOrGhost(unit))) then
		-- not (rez and unit is dead) -> color in red
		button.texture:SetVertexColor(unpack(C.colors.unitDead))
	--elseif button.hOOR and not invalid then
	elseif button.hOOR then
		-- out of range -> color in red
		button.texture:SetVertexColor(unpack(C.colors.unitOOR))
	--elseif button.hPrereqFailed and not invalid then
	elseif button.hPrereqFailed then
		-- button disabled -> color in gray
		button.texture:SetVertexColor(unpack(C.colors.spellPrereqFailed))
	--elseif button.hNotUsable and not invalid then
	elseif button.hNotUsable then
		-- button not usable -> color in medium red
		button.texture:SetVertexColor(unpack(C.colors.spellNotUsable))
	--elseif OOM and not invalid then
	elseif OOM then
		-- no mana -> color in blue
		button.texture:SetVertexColor(unpack(C.colors.OOM))
	--elseif button.hDispelHighlight ~= "none" and not invalid then
	elseif button.hDispelHighlight ~= "none" then
		-- dispel highlight -> color with debuff color
		local debuffColor = DebuffTypeColor[button.hDispelHighlight] or DebuffTypeColor["none"]
		button:SetBackdropColor(debuffColor.r, debuffColor.g, debuffColor.b)
		button.texture:SetVertexColor(debuffColor.r, debuffColor.g, debuffColor.b)
	else
		button.texture:SetVertexColor(unpack(OriginButtonVertexColor))
		button:SetBackdropColor(unpack(OriginButtonBackdropColor))
		button:SetBackdropBorderColor(unpack(OriginButtonBackdropBorderColor))
	end
end

-- Update button OOR
local function UpdateButtonOOR(frame, button, spellName)
	--PerformanceCounter:Increment(ADDON_NAME, "UpdateButtonOOR")
	local inRange = IsSpellInRange(spellName, frame.unit)
	if not inRange or inRange == 0 then
		button.hOOR = true
	else
		button.hOOR = false
	end
	UpdateButtonColor(frame, button)
end

-- Update button cooldown
local function UpdateButtonCooldownAndCharges(frame, button, start, duration, enabled, currentCharges, maxCharges)
	--PerformanceCounter:Increment(ADDON_NAME, "UpdateButtonCooldownAndCharges")
	CooldownFrame_SetTimer(button.cooldown, start, duration, enabled, currentCharges, maxCharges)
	if (button.charges and maxCharges and maxCharges > 1) then
		button.charges:SetText(currentCharges)
		button.charges:Show()
	else
		button.charges:Hide()
	end
end

-- Update frame buttons color
local function UpdateFrameButtonsColor(frame)
	--PerformanceCounter:Increment(ADDON_NAME, "UpdateFrameButtonsColor")
	if not frame.hButtons then return end
	for index, buttonHeader in ipairs(ButtonHeaders) do
		local button = frame.hButtons[index]
		UpdateButtonColor(frame, button)
	end
end

-- Update frame buff/debuff/prereq
local LastDebuffSoundTime = GetTime()
local ListBuffs = {} -- GC-friendly
local ListDebuffs = {} -- GC-friendly
local function UpdateFrameBuffsDebuffsPrereqs(frame)
	--PerformanceCounter:Increment(ADDON_NAME, "UpdateFrameBuffsDebuffsPrereqs")
--print("UpdateFrameBuffsDebuffsPrereqs:"..tostring(frame:GetName()).."  "..tostring(frame.unit))
	local unit = frame.unit
	if not unit then return end

	--PerformanceCounter:Start(ADDON_NAME, "UpdateFrameBuffsDebuffsPrereqs")

	-- reset priorityDebuff
	if frame.hPriorityDebuff then
		-- lower value ==> higher priority
		frame.hPriorityDebuff.priority = 1000 -- lower priority
		frame.hPriorityDebuff:Hide()
	end

	-- buff: parse buff even if showBuff is set to false for prereq
	--PerformanceCounter:Start(ADDON_NAME, "UpdateBuffs")
	local buffCount = 0
	if not frame.hDisabled then
		local buffIndex = 1
		for i = 1, 40, 1 do
			-- get buff, don't filter on PLAYER because we need a full list of buff to check prereq
			local filter = (CurrentSpellList and not CurrentSpellList.hasBuffPrereq and not CurrentSpellList.buffs) and "PLAYER|CANCELLABLE" or "CANCELLABLE" -- RAID cannot be used because Prayer of Mending buff is tagged as selfbuff :/
			--local name, _, icon, count, _, duration, expirationTime, unitCaster, _, _, spellID = UnitBuff(unit, i, filter)
			local name, _, icon, count, _, duration, expirationTime, unitCaster, _, _, spellID, canApplyAura, isBossDebuff, value1, value2, value3 = UnitBuff(unit, i, filter)
			if not name then break end
			if not ListBuffs[i] then ListBuffs[i] = {} end
			-- display only buff castable by player but keep whole list of buff to check prereq
			ListBuffs[i].spellID = spellID
			ListBuffs[i].spellName = name
			buffCount = buffCount + 1
			local displayValueName = nil
			local filtered = true -- default: filtered
			if C.general.showBuff == true and frame.hBuffs and buffIndex <= C.general.maxBuffCount then
				-- check buffs list
				if CurrentSpellList and CurrentSpellList.buffs and unitCaster == "player" then
					-- for index, buffSetting in pairs(CurrentSpellList.buffs) do
						-- if buffSetting.spellName == name then
							-- displayValueName = buffSetting.display
							-- filtered = false
							-- break
						-- end
					-- end
					local buffSetting = CurrentSpellList.buffs[name]
					-- .spellID, .display
					if buffSetting then
						displayValueName = buffSetting.display -- allows to display value1 or value2 or value3 when spell applies buff
						filtered = false
--print(tostring(displayValueName))
					end
				end
				-- check buff castable by player
				if filtered and unitCaster == "player" then 
					for index, buttonHeader in ipairs(ButtonHeaders) do
						local spellName = buttonHeader.hSpellName
						if spellName == name then
							displayValueName = buttonHeader.hSpell.display -- allows to display value1 or value2 or value3 when spell applies buff
--print(tostring(displayValueName))
							filtered = false
							break
						elseif buttonHeader.hMacroName then
							local macroID = GetMacroIndexByName(buttonHeader.hMacroName)
							if macroID > 0 then
								local spellName = GetMacroSpell(macroID)
								if spellName == name then
									displayValueName = buttonHeader.hSpell.display -- allows to display value1 or value2 or value3 when spell applies buff
									filtered = false
									break
								end
							end
						end
					end
				end
				if not filtered then
					-- buff displayed
					local buff = frame.hBuffs[buffIndex]
					local displayValue = nil
					if displayValueName then
						if displayValueName == "value1" then displayValue = value1
						elseif displayValueName == "value2" then displayValue = value2
						elseif displayValueName == "value3" then displayValue = value3
						end
--print(tostring(spellID).."  "..tostring(displayValueName).."  "..tostring(displayValue).." -- "..tostring(value1).."  "..tostring(value2).."  "..tostring(value3))
					end
					UpdateBuff(frame, buff, i, unit, icon, count, duration, expirationTime, spellID, name, displayValue)
					-- next buff
					buffIndex = buffIndex + 1
				end
			end
		end
		if frame.hBuffs then
			for i = buffIndex, C.general.maxBuffCount, 1 do
				-- hide remainder buff
				local buff = frame.hBuffs[i]
				buff.spellID = nil
				buff.shieldAmount = nil
				buff:Hide()
			end
		end
	end
	--PerformanceCounter:Stop(ADDON_NAME, "UpdateBuffs")

	-- debuff: parse debuff even if showDebuff is set to false for prereq and even if frame is disabled
	--PerformanceCounter:Start(ADDON_NAME, "UpdateDebuffs")
	local debuffCount = 0
	local debuffIndex = 1
	local dispellableFound = false
	if C.general.showDebuff == true then
		for i = 1, 40, 1 do
			-- get debuff
			local name, _, icon, count, debuffType, duration, expirationTime, _, _, _, spellID, _, isBossDebuff = UnitDebuff(unit, i)
			if not name then break end
			local debuffPriority = isBossDebuff and 10 or 1000 -- base priority
			if C.general.debugDebuff then
				debuffType = C.general.debugDebuff -- DEBUG purpose :)
			end
			if not ListDebuffs[i] then ListDebuffs[i] = {} end
			-- display not filtered debuff but keep whole debuff list to check prereq and highlight dispel buttons
			ListDebuffs[i].spellID = spellID
			ListDebuffs[i].type = debuffType
			ListDebuffs[i].spellName = name
			debuffCount = debuffCount + 1
			local dispellable = false -- default: non-dispellable
			if debuffType then
				for _, buttonHeader in ipairs(ButtonHeaders) do
					local spellSetting = buttonHeader.hSpell
					if not spellSetting then break end -- uninitialized headers are grouped at the end
					if spellSetting.dispels then
						local canDispel = type(spellSetting.dispels[debuffType]) == "function" and spellSetting.dispels[debuffType]() or spellSetting.dispels[debuffType]
						if canDispel then
							debuffPriority = 0 -- highest priority
							dispellable = true
							dispellableFound = true
							break
						end
					end
				end
			end
			local filtered = false -- default: not filtered
			if not dispellable then
				-- non-dispellable are rejected or filtered using blacklist/whitelist
				if C.general.debuffFilter == "DISPELLABLE" then
					filtered = true
				elseif C.general.debuffFilter == "BLACKLIST" and C.blacklist then
					-- blacklisted ?
					-- filtered = false -- default: not filtered
					-- for _, entry in ipairs(C.blacklist) do
						-- if entry.spellName == name then
							-- filtered = true -- found in blacklist -> filtered
							-- break
						-- end
					-- end
					filtered = false
					if C.blacklist[name] then filtered = true end
				elseif C.general.debuffFilter == "WHITELIST" and C.whitelist then
					-- whitelisted ?
					-- filtered = true -- default: filtered
					-- for _, entry in ipairs(C.whitelist) do
						-- if entry.spellName == name then
							-- debuffPriority = entry.priority or 10
							-- filtered = false -- found in whitelist -> not filtered
							-- break
						-- end
					-- end
					filtered = true -- default: filtered
					local entry = C.whitelist[name]
					if entry then
						filtered = false
						debuffPriority = entry.priority or 10
					end
				end
			end
			if not filtered then
				-- debuff not filtered
				if frame.hDebuffs and debuffIndex <= C.general.maxDebuffCount then
					-- set normal debuff
					local debuff = frame.hDebuffs[debuffIndex]
					UpdateDebuff(frame, debuff, i, unit, icon, count, duration, expirationTime, debuffType, spellID, name)
					-- next debuff
					debuffIndex = debuffIndex + 1
				end
				if frame.hPriorityDebuff and debuffPriority <= frame.hPriorityDebuff.priority then
					-- set priority debuff if any
					UpdateDebuff(frame, frame.hPriorityDebuff, i, unit, icon, count, duration, expirationTime, debuffType, spellID, name)
					frame.hPriorityDebuff.priority = debuffPriority
				end
			end
		end
	end
	if frame.hDebuffs then
		for i = debuffIndex, C.general.maxDebuffCount, 1 do
			-- hide remainder debuff
			local debuff = frame.hDebuffs[i]
			debuff.spellID = nil
			debuff.shieldAmount = nil
			debuff:Hide()
		end
	end
	--PerformanceCounter:Stop(ADDON_NAME, "UpdateDebuffs")

	-- color dispel button if dispellable debuff (and not in dispellable filter list) + prereqs management (is buff or debuff a prereq to enable/disable a spell) + transforms
	if frame.hButtons and not frame.hDisabled then
		--PerformanceCounter:Start(ADDON_NAME, "UpdatePrereqs")
		local isUnitInRange = UnitInRange(unit)
		local playSound = false -- play sound only if at least one debuff dispellable not filtered and option activated
		for index, buttonHeader in ipairs(ButtonHeaders) do
			local spellSetting = buttonHeader.hSpell
			if not spellSetting then break end -- uninitialized headers are grouped at the end
			local button = frame.hButtons[index]
			local change = false -- if something has changed on a button, recolor it
			-- buff prereq: if not present, spell is inactive
			if spellSetting.buffs then
				local prereqBuffFound = false
				for _, prereqBuffSpellID in ipairs(spellSetting.buffs) do
					for i = 1, buffCount, 1 do
						local buff = ListBuffs[i]
						local buffSpellID = buff.spellID
						if buffSpellID == prereqBuffSpellID then
							prereqBuffFound = true
							break
						end
					end
					if prereqBuffFound then break end
				end
				-- if not prereqBuffFound then
					-- if button.hPrereqFailed == false then change = true end
					-- button.hPrereqFailed = true
				-- else
					-- if button.hPrereqFailed == true then change = true end
					-- button.hPrereqFailed = false
				-- end
				if not prereqBuffFound ~= button.hPrereqFailed then change = true end
				button.hPrereqFailed = not prereqBuffFound
			end
			-- debuff prereq: if present, spell is inactive
			if spellSetting.debuffs then
				local prereqDebuffFound = false
				for _, prereqDebuffSpellID in ipairs(spellSetting.debuffs) do
					for i = 1, debuffCount, 1 do
						local debuff = ListDebuffs[i]
						local debuffSpellID = debuff.spellID
						if debuffSpellID == prereqDebuffSpellID then
							prereqDebuffFound = true
							break
						end
					end
					if prereqDebuffFound then break end
				end
				-- if prereqDebuffFound then
					-- if button.hPrereqFailed == false then change = true end
					-- button.hPrereqFailed = true
				-- else
					-- if button.hPrereqFailed == true then change = true end
					-- button.hPrereqFailed = false
				-- end
				if prereqDebuffFound ~= button.hPrereqFailed then change = true end
				button.hPrereqFailed = prereqDebuffFound
			end
			-- color dispel button if affected by a debuff curable by a player spell
			local dispelHighlighted = false
			if dispellableFound and spellSetting.dispels and (C.general.highlightDispel == true or C.general.dispelAnimation ~= "NONE") then
				for i = 1, debuffCount, 1 do
					local debuff = ListDebuffs[i]
					local debuffType = debuff.type
					local debuffName = debuff.spellName
					if debuffType then
						local filtered = false -- default: not filtered
						-- if C.dispellable then -- check if debuff is in dispellable filter
							-- for _, entry in ipairs(C.dispellable) do
								-- if entry.spellName == debuffName then
									-- filtered = true
									-- break
								-- end
							-- end
						-- end
						if C.dispellable[debuffName] then filtered = true end -- check if debuff is in dispellable filter (dispellable debuff displayed but not triggering dispel highlight, dispel sound, ...)
						if not filtered then
							if C.general.playSoundOnDispel == true then playSound = true end -- play sound only if at least one debuff dispellable not filtered and option activated
							local canDispel = type(spellSetting.dispels[debuffType]) == "function" and spellSetting.dispels[debuffType]() or spellSetting.dispels[debuffType]
							if canDispel then
								local debuffColor = DebuffTypeColor[debuffType] or DebuffTypeColor["none"]
								-- Highlight dispel button?
								if C.general.highlightDispel == true then
									if button.hDispelHighlight ~= debuffType then change = true end
									button.hDispelHighlight = debuffType
									dispelHighlighted = true
								end
								-- Flash dispel?
								if isUnitInRange then
									if C.general.dispelAnimation == "FLASH" then
										FlashFrame:ShowFlashFrame(button, debuffColor, 320, 100, false)
									elseif C.general.dispelAnimation == "BLINK" then
										FlashFrame:Blink(button, 0.3)
									elseif C.general.dispelAnimation == "PULSE" then
										FlashFrame:Pulse(button, 1.75)
									end
								end
								break -- a debuff dispellable is enough
							end
						end
					end
				end
			end
			if not dispelHighlighted then
				if button.hDispelHighlight ~= "none" then change = true end
				button.hDispelHighlight = "none"
			end
			if change then
				UpdateButtonColor(frame, button)
			end
		end
		-- Play sound?
		if playSound and isUnitInRange then
			local now = GetTime()
			if now > LastDebuffSoundTime + 7 then -- no more than once every 7 seconds
				PlaySoundFile(C.general.dispelSoundFile)
				LastDebuffSoundTime = now
			end
		end
		--PerformanceCounter:Stop(ADDON_NAME, "UpdatePrereqs")
	end
	--PerformanceCounter:Stop(ADDON_NAME, "UpdateFrameBuffsDebuffsPrereqs")
end

-- Update frame disable status when unit is dead/ghost/disconnected
local function UpdateFrameDisableStatus(frame)
	--PerformanceCounter:Increment(ADDON_NAME, "UpdateFrameDisableStatus")

	local unit = frame.unit
	if not unit then return end

	--PerformanceCounter:Start(ADDON_NAME, "UpdateFrameDisableStatus")
	if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then
		if not frame.hDisabled then
			frame.hDisabled = true
			-- hide buff
			if frame.hBuffs then
				for _, buff in ipairs(frame.hBuffs) do
					buff:Hide()
				end
			end
			UpdateFrameButtonsColor(frame)
		end
	elseif frame.hDisabled then
		frame.hDisabled = false
		UpdateFrameButtonsColor(frame)
	end
	--PerformanceCounter:Stop(ADDON_NAME, "UpdateFrameDisableStatus")
end

-- For each spell, show/hide glow
local function UpdateGlowingByHeader(index, buttonHeader)
	local spellName = buttonHeader.hSpellName
	if buttonHeader.hMacroName then
		local macroID = GetMacroIndexByName(buttonHeader.hMacroName)
		if macroID > 0 then
			spellName = GetMacroSpell(macroID)
		end
	end
	if spellName then
		local glow = GlowingSpells[spellName]
		if glow then
			ForEachUnitframeButton(index, ShowButtonGlow)
		else
			ForEachUnitframeButton(index, HideButtonGlow)
		end
	end
end
local function UpdateGlowing()
	for index, buttonHeader in ipairs(ButtonHeaders) do
		UpdateGlowingByHeader(index, buttonHeader)
	end
end

-- For each spell, get cooldown/charges then loop among Healium Unitframes and set cooldown
local CacheCD = {} -- keep a list of CD infos between calls, if CD information are the same, no need to update buttons
local function UpdateCooldownAndChargesByHeader(index, buttonHeader)
	local start, duration, enabled
	local currentCharges, maxCharges
	if buttonHeader.hSpellID then
		local cooldownStart, cooldownDuration
		currentCharges, maxCharges, cooldownStart, cooldownDuration = GetSpellCharges(buttonHeader.hSpellID)
		if (currentCharges and maxCharges and cooldownStart and cooldownDuration and currentCharges < maxCharges and maxCharges > 1) then
			--http://wowpedia.org/API_GetSpellCharges
--print("UpdateCooldownAndChargesByHeader1:"..(buttonHeader.hSpellID or "???").." "..(buttonHeader.hSpellName or "???").." "..(currentCharges or "?").." "..(maxCharges or "?").." "..(cooldownStart or "?").." "..(cooldownDuration or "?"))
			start = cooldownStart-- / GetTime()
			duration = cooldownDuration
			enabled = 1
		else
			start, duration, enabled = GetSpellCooldown(buttonHeader.hSpellID)
		end
	elseif buttonHeader.hMacroName then -- TODO: when macro has a keyboard:modifier  cd should only be called when modifier is pressed
		local name = GetMacroSpell(buttonHeader.hMacroName)
		if name then
			start, duration, enabled = GetSpellCooldown(name)
		else
			enabled = false
		end
	end
	local arrayEntry = CacheCD[index]
	if not arrayEntry or arrayEntry.start ~= start or arrayEntry.duration ~= duration or arrayEntry.currentCharges ~= currentCharges then
--print("UpdateCooldownAndChargesByHeader2:"..(buttonHeader.hSpellName or buttonHeader.hMacroName or "???").." "..(start or "?").." "..(duration or "?").." "..(enabled or "?"))
		--PerformanceCounter:Increment(ADDON_NAME, "UpdateCooldownAndChargesByHeader by frame")
		-- Update buttons
		ForEachUnitframeButton(index, UpdateButtonCooldownAndCharges, start, duration, enabled, currentCharges, maxCharges)
		-- Update cache
		if not CacheCD[index] then CacheCD[index] = {} end
		CacheCD[index].start = start
		CacheCD[index].duration = duration
		CacheCD[index].currentCharges = currentCharges
	-- else
		-- PerformanceCounter:Increment(ADDON_NAME, "SKIP UpdateCooldownAndChargesByHeader by frame")
	end
end
local function UpdateCooldownsAndCharges()
	--PerformanceCounter:Increment(ADDON_NAME, "UpdateCooldownsAndCharges")
	--PerformanceCounter:Start(ADDON_NAME, "UpdateCooldownsAndCharges")
	for index, buttonHeader in ipairs(ButtonHeaders) do
		UpdateCooldownAndChargesByHeader(index, buttonHeader)
	end
	--PerformanceCounter:Stop(ADDON_NAME, "UpdateCooldownsAndCharges")
end

-- Check OOM spells
local function UpdateOOMByHeader(index, buttonHeader)
	local spellName = buttonHeader.hSpellName
	if buttonHeader.hMacroName then
		local macroID = GetMacroIndexByName(buttonHeader.hMacroName)
		if macroID > 0 then
			spellName = GetMacroSpell(macroID)
		end
	end
	if spellName then
		local _, OOM = IsUsableSpell(spellName)
		if buttonHeader.hOOM ~= OOM then
			--PerformanceCounter:Increment(ADDON_NAME, "UpdateButtonOOM by header")
			-- Update button header
			buttonHeader.hOOM = OOM
			-- Update buttons
			ForEachUnitframeButton(index, UpdateButtonColor)
		-- else
			-- PerformanceCounter:Increment(ADDON_NAME, "SKIP UpdateButtonOOM by header")
		end
	end
end
local function UpdateOOM()
	--PerformanceCounter:Increment(ADDON_NAME, "UpdateOOM")
	--PerformanceCounter:Start(ADDON_NAME, "UpdateOOM")
	for index, buttonHeader in ipairs(ButtonHeaders) do
		UpdateOOMByHeader(index, buttonHeader)
	end
	--PerformanceCounter:Stop(ADDON_NAME, "UpdateOOM")
end

-- Check OOR spells
local function UpdateOORSpells()
	--PerformanceCounter:Increment(ADDON_NAME, "UpdateOORSpells")
	--PerformanceCounter:Start(ADDON_NAME, "UpdateOORSpells")
	for index, buttonHeader in ipairs(ButtonHeaders) do
		local spellName = buttonHeader.hSpellName
		if buttonHeader.hMacroName then
			local macroID = GetMacroIndexByName(buttonHeader.hMacroName)
			if macroID > 0 then
				spellName = GetMacroSpell(macroID)
			end
		end
		if spellName then
			ForEachUnitframeButton(index, UpdateButtonOOR, spellName)
		end
	end
end

-- For each spell, if transform setting exists, change icon according buff affected 'player'
local function UpdateTransforms()
--print("UpdateTransforms0:"..tostring(CurrentSpellList.hasTransforms))
	--PerformanceCounter:Increment(ADDON_NAME, "UpdateTransforms")
	--PerformanceCounter:Start(ADDON_NAME, "UpdateTransforms")
	if not CurrentSpellList or not CurrentSpellList.hasTransforms then return end
	-- If transform found and buff matches then update icon
	for index, buttonHeader in ipairs(ButtonHeaders) do
		local spellSetting = buttonHeader.hSpell
--print("UpdateTransforms 1 "..tostring(spellSetting).."  "..tostring(buttonHeader.hSpell))
		if not spellSetting then break end -- uninitialized headers are grouped at the end
		if spellSetting.transforms and spellSetting.spellID then
--print("UpdateTransforms 2")
			local transformToSpellID = spellSetting.spellID
			local transformToSpellName = spellSetting.spellName
			for _, transformSetting in pairs(spellSetting.transforms) do
--print("UpdateTransforms 3")
				local buffTransformSpellName = transformSetting.buffSpellName
				local name = UnitBuff("player", buffTransformSpellName) -- check if player is affected by buff
				if name then
--print("UpdateTransforms 4")
					transformToSpellID = transformSetting.spellID
					transformToSpellName = transformSetting.spellName
					break
				end
			end
			if buttonHeader.hSpellID ~= transformToSpellID then
--print("UpdateTransforms 5")
				--PerformanceCounter:Increment(ADDON_NAME, "UpdateButtonIcon by frame")
				-- Update current spellID/spellName/icon
				buttonHeader.hSpellID = transformToSpellID
				buttonHeader.hSpellName = transformToSpellName
				buttonHeader.hIcon = select(3, GetSpellInfo(transformToSpellID))
				-- Update buttons
				ForEachUnitframeButton(index, UpdateButtonIcon, buttonHeader)
				-- Update CD
				UpdateCooldownAndChargesByHeader(index, buttonHeader)
				-- Update glow
				UpdateGlowingByHeader(index, buttonHeader)
				-- Update OOM
				UpdateOOMByHeader(index, buttonHeader)
			-- else
				-- PerformanceCounter:Increment(ADDON_NAME, "SKIP UpdateButtonIcon by frame")
			end
		end
	end
	--PerformanceCounter:Stop(ADDON_NAME, "UpdateTransforms")
end

-- Apply/Update/Remove Shields
--[[
local function UpdateFrameUpdateShieldsOnBuffsDebuffs(frame)
	if not frame.hShields then return end
--print("UpdateFrameUpdateShieldsOnBuffsDebuffs: shields found")
	if frame.hBuffs then
		for _, buff in ipairs(frame.hBuffs) do
			local found = false
			for _, shield in ipairs(frame.hShields) do
				if shield.enabled == true and buff.spellID == shield.spellID then
					buff.shield:SetText(FormatShieldValue(shield.amount, shield.info.amount))
					buff.shield:Show()
					--buff.cooldown:Hide()
					found = true
					break
				end
			end
			if not found then
				buff.shield:Hide()
				--buff.cooldown:Show()
			end
		end
	end
	if frame.hDebuffs then
		for _, debuff in ipairs(frame.hDebuffs) do
			local found = false
			for _, shield in ipairs(frame.hShields) do
				if shield.enabled == true and debuff.spellID == shield.spellID then
					debuff.shield:SetText(FormatShieldValue(shield.amount, shield.info.amount))
					debuff.shield:Show()
					--debuff.cooldown:Show()
					found = true
					break
				end
			end
			if not found then
				debuff.shield:Hide()
				--debuff.cooldown:Hide()
			end
		end
	end
	if frame.hPriorityDebuff then
		local debuff = frame.hPriorityDebuff
		local found = false
		for _, shield in ipairs(frame.hShields) do
			if shield.enabled == true and debuff.spellID == shield.spellID then
				debuff.shield:SetText(FormatShieldValue(shield.amount, shield.info.amount))
				debuff.shield:Show()
				--debuff.cooldown:Show()
				found = true
				break
			end
		end
		if not found then
			debuff.shield:Hide()
			--debuff.cooldown:Hide()
		end
	end
end
local function UpdateFrameApplyShield(frame, spellID, shieldInfo)
--print("UpdateFrameApplyShield:"..tostring(spellID).."  "..tostring(shieldInfo))
	local found = false
	if frame.hShields then
		for _, shield in ipairs(frame.hShields) do
			if shield.spellID == spellID and shield.info.type == shieldInfo.type then
				-- refresh
				shield.amount = shieldInfo.amount or 0
				shield.enabled = true
				found = true
				break
			end
		end
	end
	if not found then
--print("NEW shield")
		if not frame.hShields then frame.hShields = {} end
		-- new
		tinsert(frame.hShields, {spellID = spellID, amount = shieldInfo.amount or 0, info = shieldInfo, enabled = true})
	end
	UpdateFrameUpdateShieldsOnBuffsDebuffs(frame)
end
local function UpdateFrameRemoveShield(frame, spellID)
	if not frame.hShields then return end
	for _, shield in ipairs(frame.hShields) do
		if not spellID or shield.spellID == spellID then
			-- remove
--print("DISABLE SHIELD:"..tostring(spellID))
			shield.enabled = false
			shield.amount = nil
			break
		end
	end
	UpdateFrameUpdateShieldsOnBuffsDebuffs(frame)
end
local function UpdateFrameUpdateShield(frame, amount, modifier)
	if not frame.hShields then return end
--print("UpdateFrameUpdateShield:"..tostring(amount).."  "..tostring(modifier))
	for _, shield in ipairs(frame.hShields) do
		if shield.info.modifier == modifier then
			if shield.info.amount then
--print("DECREASING")
				shield.amount = math.max((shield.amount or shield.info.amount) - amount, 0) -- decreasing
			else
--print("INCREASING")
				shield.amount = (shield.amount or 0) + amount -- increasing
			end
		end
	end
	UpdateFrameUpdateShieldsOnBuffsDebuffs(frame)
end
--]]

-- Update healium frame debuff position, debuff must be anchored to last shown button
local function UpdateFrameDebuffsPosition(frame)
	--PerformanceCounter:Increment(ADDON_NAME, "UpdateFrameDebuffsPosition")
	if not frame.hDebuffs or not frame.hButtons then return end
	--DEBUG(1000,"Update debuff position for "..frame:GetName())
	local style = Styles[frame.hStyle]
	local anchor = frame
	if ButtonHeaders then
		for index, buttonHeader in ipairs(ButtonHeaders) do
			anchor = frame.hButtons[index]
		end
	end
	--DEBUG(1000,"Update debuff position for "..frame:GetName().." anchoring on "..anchor:GetName())
	local firstDebuff = frame.hDebuffs[1]
	--DEBUG(1000,"anchor: "..anchor:GetName().."  firstDebuff: "..firstDebuff:GetName())
	--local debuffSpacing = C.general.debuffSpacing or 2
	local debuffSpacing = style.debuffSpacing or 2
	firstDebuff:ClearAllPoints()
	firstDebuff:SetPoint("TOPLEFT", anchor, "TOPRIGHT", debuffSpacing, 0)
end

-- Update healium frame buttons, set texture, extra attributes and show/hide.
local function UpdateFrameButtonsAttributes(frame)
	--PerformanceCounter:Increment(ADDON_NAME, "UpdateFrameButtonsAttributes")
	if InCombatLockdown() then return end

	if not frame.hButtons then return end
	CacheCD = {} -- reset CD
	GlowingSpells = {} -- reset Glow
	for i, button in ipairs(frame.hButtons) do
		local buttonHeader = (i <= #ButtonHeaders) and ButtonHeaders[i]
--print(i.."  "..tostring(buttonHeader).."  "..tostring(buttonHeader))
--print("UpdateFrameButtonsAttributes:"..tostring(frame:GetName()).."  "..tostring(i).."  "..tostring(buttonHeader or ""))
		if buttonHeader then
			--local name = buttonHeader.hSpellName and buttonHeader.hSpellName or buttonHeader.hMacroName
			local name = buttonHeader.hSpellName or buttonHeader.hMacroName
			button.hHeaderIndex = i
			button.texture:SetTexture(buttonHeader.hIcon)

			button:SetAttribute("type", buttonHeader.hType)
			button:SetAttribute(buttonHeader.hType, name)

			button:Show()
		else
			button.hHeaderIndex = nil
			button.texture:SetTexture("")
			button:Hide()
		end
		button.hPrereqFailed = false
		button.hOOM = false
		button.hDispelHighlight = "none"
		button.hOOR = false
		button.hNotUsable = false
	end
end

-- Fill button header with spellID, spellName, macroName, OOM, ...
local function UpdateButtonHeaders()
	ButtonHeaders = {} -- Reset headers
	local headerIndex = 1
	for index = 1, C.general.maxButtonCount, 1 do
		local spellSetting = (CurrentSpellList and CurrentSpellList.spells and (index <= #CurrentSpellList.spells)) and CurrentSpellList.spells[index]
--print("UpdateButtonHeaders INDEX:"..tostring(index).."  "..tostring(spellSetting))
		if spellSetting and spellSetting.invalidSpell == false then
			local buttonHeader = nil
			if spellSetting.spellID then
--print(tostring(index).."  "..tostring(spellSetting.spellID))
				--if GetSkillType(spellSetting.spellID) then
					buttonHeader = {}
					buttonHeader.hSpell = spellSetting -- no need to copy
					buttonHeader.hType = "spell"
					--buttonHeader.hSpellName, _, buttonHeader.hIcon = GetSpellInfo(spellSetting.spellID)
					buttonHeader.hSpellID = spellSetting.spellID
					buttonHeader.hSpellName = spellSetting.spellName
					buttonHeader.hIcon = select(3, GetSpellInfo(spellSetting.spellID))
				--end
			elseif spellSetting.macroName then
				if GetMacroIndexByName(spellSetting.macroName) > 0 then
					buttonHeader = {}
					buttonHeader.hSpell = spellSetting -- no need to copy
					buttonHeader.hType = "macro"
					buttonHeader.hMacroName = spellSetting.macroName
					buttonHeader.hIcon = select(2, GetMacroInfo(spellSetting.macroName))
					-- if not spellSetting.macroIcon then
						-- local macroIcon = select(2, GetMacroInfo(spellSetting.macroName))
						-- spellSetting.macroIcon = macroIcon
					-- end
					--buttonHeader.hIcon = spellSetting.macroIcon
				end
			end
			if buttonHeader then -- if button header created, add it to button header list
--print("ADD HEADER:"..tostring(headerIndex).."  "..tostring(buttonHeader.hSpellName or buttonHeader.hMacroName))
				ButtonHeaders[headerIndex] = buttonHeader
				headerIndex = headerIndex + 1
			-- else
-- print("invalid spell or macro:"..tostring(spellSetting.spellID).."  "..tostring(spellSetting.macroName))
			end
		-- else
-- print("spell setting not found:"..tostring(CurrentSpellList).."  "..tostring(CurrentSpellList.spells).."  "..tostring(index <= #CurrentSpellList.spells).."  "..tostring(CurrentSpellList.spells[index]))
		end
	end
end

-------------------------------------------------------
-- Healium buttons/buff/debuffs creation
-------------------------------------------------------
local DelayedButtonsCreation = {}

-- Create heal buttons for a frame
local function CreateHealiumButtons(frame)
	if frame.hButtons then return end
	local style = Styles[frame.hStyle]

	if InCombatLockdown() then
		tinsert(DelayedButtonsCreation, frame)
		--EventsHandler:RegisterEvent("PLAYER_REGEN_ENABLED")
		return
	end

	frame.hButtons = {}
	local size = frame:GetHeight()
	for i = 1, C.general.maxButtonCount, 1 do
--print("CreateHealiumButtons "..i.."  1")
		-- name
		local buttonName = frame:GetName().."_HealiumButton_"..i
--print("CreateHealiumButtons "..i.."  1.1 "..tostring(buttonName).."  "..tostring(frame))
		-- frame
		local button = CreateFrame("Button", buttonName, frame, "SecureActionButtonTemplate")--"SecureActionButtonTemplate, ActionButtonTemplate")
--print("CreateHealiumButtons "..i.."  1.2")
		button:SetSize(size, size)
		local anchor
		if i == 1 then
			anchor = {"TOPLEFT", frame, "TOPRIGHT", 2, 0}
		else
			anchor = {"TOPLEFT", frame.hButtons[i-1], "TOPRIGHT", 2, 0}
		end
--print("CreateHealiumButtons "..i.."  1.3")
		button:ClearAllPoints()
		button:SetPoint(unpack(anchor))
--print("CreateHealiumButtons "..i.."  1.4")
		button.texture = button:CreateTexture(nil, "ARTWORK")
		button.texture:SetAllPoints(button)
		button.cooldown = CreateFrame("Cooldown", "$parentCD", button, "CooldownFrameTemplate")
		button.cooldown:SetAllPoints(button.texture)
		button.charges = button:CreateFontString("$parentCount", "OVERLAY")
		button.charges:SetFontObject(NumberFontNormal)
		button.charges:SetPoint("BOTTOMRIGHT", 1, -1)
		button.charges:SetJustifyH("CENTER")
--print("CreateHealiumButtons "..i.."  2")
		-- skin
		if style.SkinButton then style.SkinButton(frame, button) end
--print("CreateHealiumButtons "..i.."  3")
		-- anchor
		if style.AnchorButton then style.AnchorButton(frame, button, frame.hButtons, i) end
--print("CreateHealiumButtons "..i.."  4")
		-- original color
		local vr, vg, vb = button.texture:GetVertexColor()
		OriginButtonVertexColor = vr and {vr, vg, vb} or OriginButtonVertexColor
		local br, bg, bb = button:GetBackdropColor()
		OriginButtonBackdropColor = br and {br, bg, bb} or OriginButtonBackdropColor
		local bbr, bbg, bbb = button:GetBackdropBorderColor()
		OriginButtonBackdropBorderColor = bbr and {bbr, bbg, bbb} or OriginButtonBackdropBorderColor
		-- click event/action, attributes 'type' and 'spell' are set in UpdateFrameButtonsAttributes
		button:RegisterForClicks("AnyUp")
		button:SetAttribute("useparent-unit", "true")
		button:SetAttribute("*unit2", "target")
		-- tooltip
		if C.general.showButtonTooltip == true then
			button:SetScript("OnEnter", ButtonOnEnter)
			button:SetScript("OnLeave", function(frame)
				GameTooltip:Hide()
			end)
		end
		-- custom
		button.hPrereqFailed = false
		button.hOOM = false
		button.hDispelHighlight = "none"
		button.hOOR = false
		button.hNotUsable = false

		button.hHeaderIndex = nil
		-- hide
		button:Hide()
		-- save button
		tinsert(frame.hButtons, button)
	end
end

-- Create debuffs for a frame
local function CreateHealiumDebuffs(frame)
	if frame.hDebuffs then return end
	local style = Styles[frame.hStyle]

	frame.hDebuffs = {}
	local size = frame:GetHeight()
	for i = 1, C.general.maxDebuffCount, 1 do
--print("CreateHealiumDebuffs "..i.."  1")
		-- name
		local debuffName = frame:GetName().."_HealiumDebuff_"..i
		-- frame
		local debuff = CreateFrame("Frame", debuffName, frame)
		debuff:SetSize(size, size)
		local anchor
		if i == 1 then
			anchor = {"TOPLEFT", frame, "TOPRIGHT", 2, 0}
		else
			anchor = {"TOPLEFT", frame.hDebuffs[i-1], "TOPRIGHT", 2, 0}
		end
		debuff:ClearAllPoints()
		debuff:SetPoint(unpack(anchor))
		-- icon
		debuff.icon = debuff:CreateTexture(nil, "ARTWORK")
		debuff.icon:SetAllPoints(debuff)
		-- cooldown
		debuff.cooldown = CreateFrame("Cooldown", "$parentCD", debuff, "CooldownFrameTemplate")
		debuff.cooldown:SetAllPoints(debuff.icon)
		debuff.cooldown:SetReverse()
		-- count
		debuff.count = debuff:CreateFontString("$parentCount", "OVERLAY")
		debuff.count:SetFontObject(NumberFontNormal)
		debuff.count:SetPoint("BOTTOMRIGHT", 1, -1)
		debuff.count:SetJustifyH("CENTER")
		-- shield
		debuff.shield = debuff:CreateFontString("$parentShield", "OVERLAY")
		debuff.shield:SetFontObject(NumberFontNormal)
		--debuff.shield:SetPoint("TOP", 1, 1)
		--debuff.shield:SetJustifyH("CENTER")
		debuff.shield:SetPoint("CENTER", 0, 0)
		debuff.shield:SetJustifyH("CENTER")
--print("CreateHealiumDebuffs "..i.."  2")
		-- skin
		if style.SkinDebuff then style.SkinDebuff(frame, debuff) end
--print("CreateHealiumDebuffs "..i.."  3")
		-- anchor
		if style.AnchorDebuff then style.AnchorDebuff(frame, debuff, frame.hDebuffs, i) end
--print("CreateHealiumDebuffs "..i.."  4")
		-- tooltip
		if C.general.showDebuffTooltip == true then
			debuff:SetScript("OnEnter", DebuffOnEnter)
			debuff:SetScript("OnLeave", function(frame)
				GameTooltip:Hide()
			end)
		end
--print("CreateHealiumDebuffs "..i.."  5")
		-- hide
		debuff:Hide()
		-- save debuff
		tinsert(frame.hDebuffs, debuff)
	end
end

-- Create buffs for a frame
local function CreateHealiumBuffs(frame)
	if frame.hBuffs then return end
	local style = Styles[frame.hStyle]

	frame.hBuffs = {}
	local size = frame:GetHeight()
	for i = 1, C.general.maxBuffCount, 1 do
		-- name
		local buffName = frame:GetName().."_HealiumBuff_"..i
		-- frame
		local buff = CreateFrame("Frame", buffName, frame)
		buff:SetSize(size, size)
		local anchor
		if i == 1 then
			anchor = {"TOPRIGHT", frame, "TOPLEFT", -2, 0}
		else
			anchor = {"TOPRIGHT", frame.hBuffs[i-1], "TOPLEFT", -2, 0}
		end
		buff:ClearAllPoints()
		buff:SetPoint(unpack(anchor))
		-- icon
		buff.icon = buff:CreateTexture(nil, "ARTWORK")
		-- buff.icon:SetPoint("TOPLEFT", 2, -2)
		-- buff.icon:SetPoint("BOTTOMRIGHT", -2, 2)
		buff.icon:SetAllPoints(buff)
		-- cooldown
		buff.cooldown = CreateFrame("Cooldown", "$parentCD", buff, "CooldownFrameTemplate")
		buff.cooldown:SetAllPoints(buff.icon)
		buff.cooldown:SetReverse()
		-- count
		buff.count = buff:CreateFontString("$parentCount", "OVERLAY")
		buff.count:SetFontObject(NumberFontNormal)
		buff.count:SetPoint("BOTTOMRIGHT", 1, -1)
		buff.count:SetJustifyH("CENTER")
		-- shield
		buff.shield = buff:CreateFontString("$parentShield", "OVERLAY")
		buff.shield:SetFontObject(NumberFontNormalSmall)
		-- buff.shield:SetPoint("TOP", 1, 1)
		-- buff.shield:SetJustifyH("CENTER")
		buff.shield:SetPoint("CENTER", 0, 0)
		buff.shield:SetJustifyH("CENTER")
		-- skin
		if style.SkinBuff then style.SkinBuff(frame, buff) end
		-- anchor
		if style.AnchorBuff then anchor = style.AnchorBuff(frame, buff, frame.hBuffs, i) end
		-- tooltip
		if C.general.showBuffTooltip == true then
			buff:SetScript("OnEnter", BuffOnEnter)
			buff:SetScript("OnLeave", function(frame)
				GameTooltip:Hide()
			end)
		end
		-- hide
		buff:Hide()
		-- save buff
		tinsert(frame.hBuffs, buff)
	end
end

-- Create unique debuff frame showing most important debuff
local function CreateHealiumPriorityDebuff(frame)
	if frame.hPriorityDebuff then return end
	local style = Styles[frame.hStyle]
	local size = frame:GetHeight()
	local debuffName = frame:GetName().."_HealiumPriorityDebuff"
	-- frame
	local debuff = CreateFrame("Frame", debuffName, frame)
	debuff:SetSize(size, size)
	local anchor = {"CENTER", frame, "CENTER", 10, 0}
	debuff:SetPoint(unpack(anchor))
	-- icon
	debuff.icon = debuff:CreateTexture(nil, "ARTWORK")
	debuff.icon:SetAllPoints(debuff)
	-- cooldown
	debuff.cooldown = CreateFrame("Cooldown", "$parentCD", debuff, "CooldownFrameTemplate")
	debuff.cooldown:SetAllPoints(debuff.icon)
	debuff.cooldown:SetReverse()
	-- count
	debuff.count = debuff:CreateFontString("$parentCount", "OVERLAY")
	debuff.count:SetFontObject(NumberFontNormal)
	debuff.count:SetPoint("BOTTOMRIGHT", 1, -1)
	debuff.count:SetJustifyH("CENTER")
	-- shield
	debuff.shield = debuff:CreateFontString("$parentShield", "OVERLAY")
	debuff.shield:SetFontObject(NumberFontNormal)
	-- debuff.shield:SetPoint("TOP", 1, 1)
	-- debuff.shield:SetJustifyH("CENTER")
	debuff.shield:SetPoint("CENTER", 0, 0)
	debuff.shield:SetJustifyH("CENTER")

	-- skin
	if style.SkinDebuff then style.SkinDebuff(frame, debuff) end
	-- anchor
	if style.AnchorDebuff then style.AnchorDebuff(frame, debuff) end
	-- tooltip
	if C.general.showDebuffTooltip == true then
		debuff:SetScript("OnEnter", DebuffOnEnter)
		debuff:SetScript("OnLeave", function(frame)
			GameTooltip:Hide()
		end)
	end
	debuff:Hide()
	frame.hPriorityDebuff = debuff
end

-- Create delayed buttons
local function CreateDelayedButtons()
	if InCombatLockdown() then return false end
	if not DelayedButtonsCreation or #DelayedButtonsCreation == 0 then return false end

	for _, frame in ipairs(DelayedButtonsCreation) do
		if not frame.hButtons then
			CreateHealiumButtons(frame)
		end
	end
	DelayedButtonsCreation = {}
	return true
end

-- Register a frame in Healium
function H:RegisterFrame(frame, styleName)
--print("RegisterFrame 0")
	if not HealiumInitialized then return false end
--print("RegisterFrame 1")
	assert(styleName, "Missing style in HealiumCore:RegisterFrame")
	if not styleName then return false end
--print("RegisterFrame 2")
	local style = Styles[styleName]
	assert(style, "Healium style "..tostring(styleName).." not registered")
	if not style then return false end
--print("RegisterFrame 3")
	frame.hStyle = styleName
	-- heal buttons
	CreateHealiumButtons(frame)
--print("RegisterFrame 4")
	-- healium debuffs
	if C.general.showDebuff == true then
		if style.PriorityDebuff == true then
			CreateHealiumPriorityDebuff(frame)
		else
			CreateHealiumDebuffs(frame)
		end
	end
--print("RegisterFrame 5")
	-- healium buffs
	if C.general.showBuff == true then
		CreateHealiumBuffs(frame)
	end
--print("RegisterFrame 6")
	-- update healium buttons visibility, icon and attributes + reposition debuff
	UpdateFrameButtonsAttributes(frame)
	-- update debuff position
	UpdateFrameDebuffsPosition(frame)
	-- custom
	frame.hDisabled = false
	-- save frame in healium frame list
	SaveUnitframe(frame)
	-- -- set OnAttributeChanged event
	-- if not frame.hHooked then
-- print("HOOKING")
		-- frame:HookScript("OnAttributeChanged", UnitframeOnAttributeChanged)
		-- --frame:SetAttribute("unit", "player") -> trigger event
		-- --frame.unit = "player" -> dont trigger event
		-- frame.hHooked = true
	-- end
	-- frame.tagada = function(self)
		-- print("TAGADA")
	-- end
	-- print(tostring(frame:GetName()).."  "..tostring(frame))

	return true
end

-------------------------------------------------------
-- Dump
-------------------------------------------------------
function H:DumpInformation(onlyShown)
	local infos = {}
	infos.LibVersion = GetAddOnMetadata(ADDON_NAME, "version")
	infos.PerformanceCounter = PerformanceCounter:Get(ADDON_NAME)
	infos.Units = {}
	infos.Headers = {}
	for i, header in ipairs(ButtonHeaders) do
		infos.Headers[i] = {}
		local infoHeader = infos.Headers[i]
		infoHeader.SpellID = header.hSpellID
		infoHeader.SpellName = header.hSpellName
		infoHeader.MacroName = header.hMacroName
		infoHeader.Icon = header.hIcon
		infoHeader.OOM = header.hOOM
	end
	ForEachUnitframeEvenIfInvalid(
		function (frame)
			if onlyShown == true and not frame:IsShown() then return end
			infos.Units[frame:GetName()] = {}
			local unitInfo = infos.Units[frame:GetName()]
			unitInfo.Unit = frame.unit
			unitInfo.Unitname = frame.unit and UnitName(frame.unit) or nil
			unitInfo.Disabled = frame.hDisabled
			unitInfo.Buttons = {}
			for i = 1, C.general.maxButtonCount, 1 do
				local button = frame.hButtons[i]
				if not onlyShown or button:IsShown() then
					unitInfo.Buttons[i] = {}
					--local invalid, spellID, spellName, macroName, icon, OOM = GetButtonSpellInfo(button)
					local spellID, spellName, macroName, icon, OOM = GetButtonSpellInfo(button)
					local buttonInfo = unitInfo.Buttons[i]
					buttonInfo.Texture = icon
					buttonInfo.IsShown = button:IsShown()
					buttonInfo.SpellID = spellID
					buttonInfo.SpellName = spellName
					buttonInfo.MacroName = macroName
					buttonInfo.OOM = OOM
					buttonInfo.NotUsable = button.hNotUsable
					buttonInfo.DispelHighlight = button.hDispelHighlight
					buttonInfo.OOR = button.hOOR
				end
			end
			unitInfo.Buffs = {}
			for i = 1, C.general.maxBuffCount, 1 do
				local buff = frame.hBuffs[i]
				if not onlyShown or buff:IsShown() then
					unitInfo.Buffs[i] = {}
					local buffInfo = unitInfo.Buffs[i]
					buffInfo.IsShown = buff:IsShown()
					buffInfo.Icon = buff.icon and buff.icon:GetTexture() or nil
					buffInfo.Count = buff.count:GetText()
					buffInfo.ID = buff:GetID()
				end
			end
			unitInfo.Debuffs = {}
			for i = 1, C.general.maxDebuffCount, 1 do
				local debuff = frame.hDebuffs[i]
				if not onlyShown or debuff:IsShown() then
					unitInfo.Debuffs[i] = {}
					local debuffInfo = unitInfo.Debuffs[i]
					debuffInfo.IsShown = debuff:IsShown()
					debuffInfo.Icon = debuff.icon and debuff.icon:GetTexture() or nil
					debuffInfo.Count = debuff.count:GetText()
					debuffInfo.ID = debuff:GetID()
				end
			end
		end
	)
	return infos
end

-------------------------------------------------------
-- Events handler
-------------------------------------------------------
function EventsHandler:GROUP_ROSTER_UPDATE()
	-- TODO: event is fired once by member -> optimize
	ForEachUnitframeEvenIfInvalid(UpdateFrameButtonsAttributes)
	ForEachUnitframeEvenIfInvalid(UpdateFrameDebuffsPosition)
	ForEachUnitframe(UpdateFrameBuffsDebuffsPrereqs)
	UpdateTransforms()
	UpdateCooldownsAndCharges()
end
-- end

function EventsHandler:PLAYER_REGEN_ENABLED()
	local created = CreateDelayedButtons()
	if created then
		--EventsHandler:UnregisterEvent("PLAYER_REGEN_ENABLED")

		ForEachUnitframe(UpdateFrameButtonsAttributes)
		ForEachUnitframe(UpdateFrameDebuffsPosition)
		ForEachUnitframe(UpdateFrameBuffsDebuffsPrereqs)
		UpdateTransforms()
		UpdateCooldownsAndCharges()
	end
--[[
	if C.general.showShields == true then
		EventsHandler:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- only in combat
	end
--]]
end

function EventsHandler:PLAYER_REGEN_DISABLED()
--[[
	if C.general.showShields == true then
		if IsValidZoneForShields() then
			EventsHandler:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- TEST
		else
			EventsHandler:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED") -- TEST
		end
	end
--]]
end

--[[
-- Shield
local ShieldActions = {
	SPELL_AURA_APPLIED		= {1, UpdateFrameApplyShield},
	SPELL_AURA_APPLIED_DOSE	= {1, UpdateFrameApplyShield},
	SPELL_AURA_REFRESH		= {1, UpdateFrameApplyShield},
	SPELL_AURA_REMOVED		= {1, UpdateFrameRemoveShield},
	SPELL_AURA_BROKEN		= {1, UpdateFrameRemoveShield},
	SPELL_AURA_BROKEN_SPELL	= {1, UpdateFrameRemoveShield},
	SPELL_HEAL				= {2, UpdateFrameUpdateShield},
	SPELL_PERIODIC_HEAL		= {2, UpdateFrameUpdateShield},
	UNIT_DIED				= {3, UpdateFrameRemoveShield},
}
function EventsHandler:COMBAT_LOG_EVENT_UNFILTERED(timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, ...)-- http://www.wowwiki.com/API_COMBAT_LOG_EVENT
--print("COMBAT_LOG_EVENT_UNFILTERED")
	local action = ShieldActions[event]
	if action then
		local spellID = select(1, ...)
		if action[1] == 1 then
			local shieldInfo = C.shields and C.shields[spellID]
			if shieldInfo then
--print("COMBAT_LOG_EVENT_UNFILTERED:"..tostring(event).."  "..tostring(destGUID).."  "..tostring(action[1]).."  "..tostring(spellID).."  "..tostring(shieldInfo).."  "..tostring(unit))
				-- for _, frame in ipairs(Unitframes) do
					-- if frame and frame.unit then
						-- local unitGUID = UnitGUID(frame.unit)
						-- if destGUID == unitGUID then
							-- action[2](frame, spellID, shieldInfo)
						-- end
					-- end
				-- end
				ForEachUnitframeWithGUID(destGUID, action[2], spellID, shieldInfo)
			end
		elseif action[1] == 2 then
--print("COMBAT_LOG_EVENT_UNFILTERED:"..tostring(event).."  "..tostring(destGUID).."  "..tostring(action[1]).."  "..tostring(unit).."  "..tostring(amount))
			local amount, overheal, absorbed, critical = select(4, ...)
			-- for _, frame in ipairs(Unitframes) do
				-- if frame and frame.unit then
					-- local unitGUID = UnitGUID(frame.unit)
					-- if destGUID == unitGUID then
						-- action[2](frame, absorbed, "ABSORB")
						-- --action[2](frame, amount, "HEAL")
					-- end
				-- end
			-- end
--print(tostring(amount).."  "..tostring(overheal).."  "..tostring(absorbed).."  "..tostring(critical))
			if absorbed and absorbed > 0 then
--print("ABSORBED  "..tostring(absorbed))
				ForEachUnitframeWithGUID(destGUID, action[2], absorbed, "ABSORB")
			end
		elseif action[1] == 3 then
			-- for _, frame in ipairs(Unitframes) do
				-- if frame and frame.unit then
					-- local unitGUID = UnitGUID(frame.unit)
					-- if destGUID == unitGUID then
						-- action[2](frame)
					-- end
				-- end
			-- end
			ForEachUnitframeWithGUID(destGUID, action[2])
		end
	end
end
--]]

function EventsHandler:SPELL_UPDATE_COOLDOWN()
	UpdateCooldownsAndCharges()
end

function EventsHandler:UNIT_AURA(unit)
	ForEachUnitframeWithUnit(unit, UpdateFrameBuffsDebuffsPrereqs)
	if unit == "player" then
		UpdateTransforms() -- buff/debuff may affect transformed spell
	end
end

local function PowerModified(self)
	local timeSpan = GetTime() - EventsHandler.hTimeSincePreviousOOMCheck
	if timeSpan > UpdateDelay then
		--PerformanceCounter:Increment(ADDON_NAME, "UpdateOOM")
		UpdateOOM()
		EventsHandler.hTimeSincePreviousOOMCheck = GetTime()
	-- else
		-- PerformanceCounter:Increment(ADDON_NAME, "SKIP UpdateOOM")
	end
end
function EventsHandler:UNIT_POWER(unit)
	--if unit == "player" then
		PowerModified()
	--end
end
function EventsHandler:UNIT_MAXPOWER(unit)
	--if unit == "player" then
		PowerModified()
	--end
end

function EventsHandler:UNIT_CONNECTION(unit)
	ForEachUnitframeWithUnit(unit, UpdateFrameDisableStatus)
end

function EventsHandler:UNIT_HEALTH_FREQUENT(unit)
	ForEachUnitframeWithUnit(unit, UpdateFrameDisableStatus)
end

function EventsHandler:SPELL_ACTIVATION_OVERLAY_GLOW_SHOW(spellID)
	AddGlowingSpell(spellID)
	UpdateGlowing()
end

function EventsHandler:SPELL_ACTIVATION_OVERLAY_GLOW_HIDE(spellID)
	RemoveGlowingSpell(spellID)
	UpdateGlowing()
end

local function OnUpdate(self, elapsed)
	self.hTimeSinceLastUpdate = self.hTimeSinceLastUpdate + elapsed
	if self.hTimeSinceLastUpdate > UpdateDelay then
		if C.general.showOOR == true then
			UpdateOORSpells()
		end
		self.hTimeSinceLastUpdate = 0
	end
end

-- OnEvent, call matching event handler
local function OnEvent(self, event, ...)
--INFO("Event: "..tostring(event).."  "..tostring(self[event]))
	if self[event] then
		self[event](self, ...)
	else
		ERROR("Missing event handler for "..tostring(event))
	end
end

function H:Enable()	-- Register event handlers
	if HealiumEnabled then return end
	HealiumEnabled = true
	--INFO("Enabling events handler")
	EventsHandler.hTimeSincePreviousOOMCheck = GetTime()
	EventsHandler:RegisterEvent("GROUP_ROSTER_UPDATE")
	EventsHandler:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	EventsHandler:RegisterEvent("UNIT_AURA")
	if C.general.showOOM == true then
		EventsHandler:RegisterUnitEvent("UNIT_POWER", "player")
		EventsHandler:RegisterUnitEvent("UNIT_MAXPOWER", "player")
	end
	EventsHandler:RegisterEvent("UNIT_HEALTH_FREQUENT")
	EventsHandler:RegisterEvent("UNIT_CONNECTION")
	EventsHandler:RegisterEvent("PLAYER_REGEN_ENABLED")
	EventsHandler:RegisterEvent("PLAYER_REGEN_DISABLED")
	if C.general.showGlow == true then
		EventsHandler:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
		EventsHandler:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
	end
	EventsHandler:SetScript("OnEvent", OnEvent)
	EventsHandler.hTimeSinceLastUpdate = GetTime()
	EventsHandler:SetScript("OnUpdate", OnUpdate)
end

function H:Disable()	-- Unregister event handlers
	if not HealiumEnabled then return end
	HealiumEnabled = false
	--INFO("Disabling events handler")
	EventsHandler:UnregisterEvent("GROUP_ROSTER_UPDATE")
	EventsHandler:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
	EventsHandler:UnregisterEvent("UNIT_AURA")
	EventsHandler:UnregisterEvent("UNIT_POWER")
	EventsHandler:UnregisterEvent("UNIT_MAXPOWER")
	EventsHandler:UnregisterEvent("UNIT_HEALTH_FREQUENT")
	EventsHandler:UnregisterEvent("UNIT_CONNECTION")
	EventsHandler:UnregisterEvent("PLAYER_REGEN_ENABLED")
	EventsHandler:UnregisterEvent("PLAYER_REGEN_DISABLED")
	EventsHandler:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
	EventsHandler:UnregisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
	EventsHandler:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	EventsHandler:SetScript("OnEvent", nil)
	EventsHandler:SetScript("OnUpdate", nil)
end

-------------------------------------------------------
-- Initialize
-------------------------------------------------------
function H:Initialize(config)
	if HealiumInitialized then return end
	HealiumInitialized = true

	-- Merge parameter config with Healium config
	if config then
		for key, value in pairs(config) do
			if C[key] then -- found in Healium config
				--DEBUG(1, "Merging config "..tostring(key))
				if type(value) == "table" then
					for subKey, subValue in pairs(value) do
						if C[key][subKey] ~= nil then
							--DEBUG(1, "Overriding "..tostring(subKey).."->"..tostring(C[key][subKey]).." with "..tostring(subValue))
							C[key][subKey] = DeepCopy(subValue)
						else
							--DEBUG(1, "Copying "..tostring(subKey).."->"..tostring(subValue))
							C[key][subKey] = DeepCopy(subValue)
						end
					end
				else
					--DEBUG(1, "Overriding "..tostring(key).."->"..tostring(C[key]).." with "..tostring(value))
					C[key] = DeepCopy(value) -- should never happens
				end
			end
		end
	end

	-- Initialize settings
	InitializeSettings()

	-- -- Create event handler
	-- EventsHandler.hTimeSincePreviousOOMCheck = GetTime()
	-- EventsHandler:RegisterEvent("GROUP_ROSTER_UPDATE")
	-- EventsHandler:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	-- EventsHandler:RegisterEvent("UNIT_AURA")
	-- if C.general.showOOM == true then
		-- EventsHandler:RegisterUnitEvent("UNIT_POWER", "player")
		-- EventsHandler:RegisterUnitEvent("UNIT_MAXPOWER", "player")
	-- end
	-- EventsHandler:RegisterEvent("UNIT_HEALTH_FREQUENT")
	-- EventsHandler:RegisterEvent("UNIT_CONNECTION")
	-- EventsHandler:RegisterEvent("PLAYER_REGEN_ENABLED")
	-- EventsHandler:RegisterEvent("PLAYER_REGEN_DISABLED")
	-- if C.general.showGlow == true then
		-- EventsHandler:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW")
		-- EventsHandler:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE")
	-- end

	-- -- Set OnEvent handlers
	-- EventsHandler:SetScript("OnEvent", function(self, event, ...)
-- --print("Event: "..tostring(event).."  "..tostring(self[event]))
		-- self[event](self, ...)
	-- end)

	-- EventsHandler.hTimeSinceLastUpdate = GetTime()
	-- EventsHandler:SetScript("OnUpdate", OnUpdate)
end

-------------------------------------------------------
-- Spell List
-------------------------------------------------------
function H:RegisterSpellList(name, spellList, buffList)
	-- Cannot modify current setting while in combat
	if name == CurrentSpellListName and InCombatLockdown() then
		ERROR(L.SPELLLIST_INCOMBAT)
		return false
	else
		CurrentSpellList = nil -- deactivate current spell list to avoid conflict
		-- TODO: stop every functions using CurrentSpellList and set a lock variable to avoid running functions using CurrentSpellList
	end

--print("Register SpellList "..tostring(name))

	-- Add spell list
	SpellListCache[name] = {} -- TODO: compare with previous entry and update only different fields
	local entry = SpellListCache[name]
	if not spellList then
		WARNING(L.CHECKSPELL_NOSPELLSFOUND)
	else
		entry.spells = {}
		local buffPrereqFound = false
		local debuffPrereqFound = false
		local transformsFound = false
		local index = 1
		--for _, paramSpellSetting in pairs(spellList) do
		--for _, paramSpellSetting in ipairs(spellList) do
		for i = 1, C.general.maxButtonCount, 1 do
			local paramSpellSetting = spellList[i]
			if paramSpellSetting then
				local spellSetting = nil -- will be assigned after copy from paramSpellSetting
				-- Copy predefined spell
				if paramSpellSetting.id then
					if not C[H.myclass].predefined then
						ERROR(L.INITIALIZE_PREDEFINEDLISTNOTFOUND)
					end
					local predefined = C[H.myclass].predefined[paramSpellSetting.id]
					if predefined then
						entry.spells[index] = DeepCopy(predefined)
						spellSetting = entry.spells[index]
						index = index + 1
					else
						ERROR(string.format(L.INITIALIZE_PREDEFINEDIDNOTFOUND, tostring(paramSpellSetting.id)))
					end
				else
					entry.spells[index] = DeepCopy(paramSpellSetting)
					spellSetting = entry.spells[index]
					index = index + 1
				end
				if spellSetting then
					-- SpellName
					if spellSetting.spellID then
						local spellName = GetSpellInfo(spellSetting.spellID)
						spellSetting.spellName = spellName
					end
--print("RegisterSpellList:"..tostring(index).."  "..tostring(spellSetting.spellName or spellSetting.macroName))
					-- Transforms
					if spellSetting.transforms then
						for buffTransformSpellID, transformSetting in pairs(spellSetting.transforms) do
							if transformSetting.spellID then
								local spellName = GetSpellInfo(transformSetting.spellID)
								local buffSpellName = GetSpellInfo(buffTransformSpellID)
								transformSetting.buffSpellName = buffSpellName
								transformSetting.spellName = spellName
							end
						end
						transformsFound = true
					end
					-- Buff prereq ?
					if spellSetting.buffs then buffPrereqFound = true end
					-- Debuff prereq ?
					if spellSetting.debuffs then debuffPrereqFound = true end
				end
			end
		end
		-- Prereq
		if buffPrereqFound == true then entry.hasBuffPrereq = true end
		if debuffPrereqFound == true then entry.hasDebuffPrereq = true end
		if transformsFound == true then entry.hasTransforms = true end
	end
--[[
	-- Spells
	if not spellList then
		WARNING(L.CHECKSPELL_NOSPELLSFOUND)
	else
		-- Copy spell list
		entry.spells = DeepCopy(spellList)
		-- Gather additional informations about spell list
		local buffPrereqFound = false
		local debuffPrereqFound = false
		local transformsFound = false
		--for index, spellSetting in ipairs(entry.spells) do
		for index, spellSetting in pairs(entry.spells) do
print("RegisterSpellList INDEX:"..tostring(index).."  "..tostring(spellSetting))
			-- Copy predefined spell
			if spellSetting.id then
				if not C[H.myclass].predefined then
					ERROR(L.INITIALIZE_PREDEFINEDLISTNOTFOUND)
				end
				local predefined = C[H.myclass].predefined[spellSetting.id]
				if predefined then
					entry.spells[index] = DeepCopy(predefined)
					spellSetting = entry.spells[index]
				else
					ERROR(string.format(L.INITIALIZE_PREDEFINEDIDNOTFOUND, tostring(spellSetting.id)))
				end
			end
			-- SpellName
			if spellSetting.spellID then
				local spellName = GetSpellInfo(spellSetting.spellID)
				spellSetting.spellName = spellName
			end
			-- Transforms
			if spellSetting.transforms then
				for buffTransformSpellID, transformSetting in pairs(spellSetting.transforms) do
					if transformSetting.spellID then
						local spellName = GetSpellInfo(transformSetting.spellID)
						local buffSpellName = GetSpellInfo(buffTransformSpellID)
						transformSetting.buffSpellName = buffSpellName
						transformSetting.spellName = spellName
					end
				end
				transformsFound = true
			end
			-- Buff prereq ?
			if spellSetting.buffs then buffPrereqFound = true end
			-- Debuff prereq ?
			if spellSetting.debuffs then debuffPrereqFound = true end
		end
		-- Prereq
		if buffPrereqFound == true then entry.hasBuffPrereq = true end
		if debuffPrereqFound == true then entry.hasDebuffPrereq = true end
		if transformsFound == true then entry.hasTransforms = true end
	end
--]]
	-- Buffs
	if buffList then
		-- Build buff list, map spellID | {spellID[, display]} to [spellName] = {spellID[, display]}
		entry.buffs = {}
		--for index, buffSpellID in ipairs(buffList) do
		for _, item in ipairs(buffList) do
			local buffSpellID = nil
			if type(item) == "number" then
				buffSpellID = item
			elseif type(item) == "table" then
				buffSpellID = item.spellID
			end
			local spellName = GetSpellInfo(buffSpellID)
			--item.buffs[index] = {spellID = buffSpellID, spellName = spellName}
			if spellName then
				if type(item) == "table" then
					entry.buffs[spellName] = {spellID = buffSpellID, display = item.display}
				else
					entry.buffs[spellName] = {spellID = buffSpellID}
				end
			end
		end
	end

	-- If registering current spell list, activate it
	if name == CurrentSpellListName then
		CurrentSpellListName = nil
		return H:ActivateSpellList(name)
	end
	-- OK
	return true
end

function H:ActivateSpellList(name)
	-- Impossible while in combat
	if InCombatLockdown() then
		ERROR(L.SPELLLIST_INCOMBAT)
		return false
	end
	-- if name == CurrentSpellListName then
		-- return false
	-- end
	CurrentSpellListName = name
	CurrentSpellList = SpellListCache[name]
-- if CurrentSpellList then
-- print("Activating SpellList "..tostring(name))
-- else
-- print("No SpellList for "..tostring(name))
-- end
	-- Check SpellList
	if CurrentSpellList then
		if not CurrentSpellList.spells then
			WARNING(L.CHECKSPELL_NOSPELLSFOUND)
		else
			--for _, spellSetting in ipairs(CurrentSpellList.spells) do
			for _, spellSetting in pairs(CurrentSpellList.spells) do
				spellSetting.invalidSpell = false
				-- if spellSetting.spellID and not GetSkillType(spellSetting.spellID) then
					-- local name = GetSpellInfo(spellSetting.spellID)
					-- if name then
						-- WARNING(string.format(L.CHECKSPELL_SPELLNOTLEARNED, name, spellSetting.spellID))
					-- else
						-- ERROR(string.format(L.CHECKSPELL_SPELLNOTEXISTS, spellSetting.spellID))
					-- end
				-- elseif spellSetting.macroName and GetMacroIndexByName(spellSetting.macroName) == 0 then
					-- ERROR(string.format(L.CHECKSPELL_MACRONOTFOUND, spellSetting.macroName))
				-- end
--print("SPELLID:"..tostring(spellSetting.spellID).."  "..tostring(spellSetting.spellName))
				if spellSetting.spellID then
					local isKnown, spellName = IsSpellKnown(spellSetting.spellID)
--print(tostring(spellSetting.spellID).."  "..tostring(isKnown).."  "..tostring(spellName))
					if spellName then
						if isKnown == "FUTURESPELL" then -- Spell not yet available (not high level enough)
							WARNING(string.format(L.CHECKSPELL_NOTYETLEARNED, spellName, spellSetting.spellID))
							spellSetting.invalidSpell = true
						elseif isKnown == "INVALIDSPEC" then -- Spell only available in other spec
							ERROR(string.format(L.CHECKSPELL_INVALIDSPEC, spellName, spellSetting.spellID))
							spellSetting.invalidSpell = true
						elseif isKnown == "NOTAVAILABLE" then -- Talent not yet available (not high level enough)
							WARNING(string.format(L.CHECKSPELL_NOTAVAILABLE, spellName, spellSetting.spellID))
							spellSetting.invalidSpell = true
						elseif isKnown == "NOTSELECTED" then -- Talent not selected
							WARNING(string.format(L.CHECKSPELL_NOTSELECTED, spellName, spellSetting.spellID))
							spellSetting.invalidSpell = true
						end
					else
						if spellSetting.id then -- Invalid predefined ID
							ERROR(string.format(L.INITIALIZE_PREDEFINEDIDNOTFOUND, spellSetting.id))
							spellSetting.invalidSpell = true
						else
							ERROR(string.format(L.CHECKSPELL_SPELLNOTEXISTS, spellSetting.spellID)) -- inexisting spell
							spellSetting.invalidSpell = true
						end
					end
				elseif spellSetting.macroName then
					if GetMacroIndexByName(spellSetting.macroName) <= 0 then
						ERROR(string.format(L.CHECKSPELL_MACRONOTFOUND, spellSetting.macroName)) -- inexisting macro
						spellSetting.invalidSpell = true
					end
				end
			end
		end
	end
	-- TODO if spell list is empty, unregister SPELL_UPDATE_COOLDOWN

	-- Update headers, buttons, buffs/debuffs/prereqs, CD, transforms
	UpdateButtonHeaders()
	ForEachUnitframeEvenIfInvalid(UpdateFrameButtonsAttributes)
	ForEachUnitframeEvenIfInvalid(UpdateFrameDebuffsPosition)
	ForEachUnitframe(UpdateFrameBuffsDebuffsPrereqs)
	ForEachUnitframe(UpdateFrameButtonsColor) -- we have to refresh color, otherwise prereq failed are not updated
	UpdateTransforms()
	UpdateCooldownsAndCharges()
	-- OK
	return true
end
