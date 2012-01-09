-------------------------------------------------------
-- Helpers
-------------------------------------------------------
-- APIs:
-- ERROR(...)
-- WARNING(...)
-- DEBUG(lvl, ...)
-- GetSpellBookID(spellName)
-- GetSkillType(spellID)
-- DeepCopy(object)
-- GetSpellID(spellName)
-- TRemoveByVal(table, val)

local ADDON_NAME, ns = ...
local H, C, L = unpack(select(2,...))
local Private = ns.Private

function Private.ERROR(...)
	local line = "|CFFFF0000HealiumCore|r:" .. strjoin(" ", ...)
	print(line)
end

function Private.WARNING(...)
	local line = "|CFFFFFF00HealiumCore|r:" .. strjoin(" ", ...)
	print(line)
end

local tekWarningDisplayed = false
local tekDebugFrame = tekDebug and tekDebug:GetFrame(ADDON_NAME) -- tekDebug support
function Private.DEBUG(lvl, ...)
	--print(tostring(lvl).."  "..type(lvl).."  "..strjoin(" ", ...))
	local params = strjoin(" ", ...)
	if type(lvl) ~= "number" then
		Private.ERROR("INVALID DEBUG (lvl not a number)"..params)
	end
	if C.general.debug and C.general.debug >= lvl then
		local line = "|CFF00FF00HC|r:" .. params
		if tekDebugFrame then
			tekDebugFrame:AddMessage(line)
		else
			if not tekWarningDisplayed then
				Private.WARNING("tekDebug not found. Debug message disabled") -- TODO: localization
				tekWarningDisplayed = true
			end
		end
	end
end

-- Get book spell id from spell name
function Private.GetSpellBookID(spellName)
	for i = 1, 300, 1 do
		local spellBookName = GetSpellBookItemName(i, BOOKTYPE_SPELL)--SpellBookFrame.bookType)
		if not spellBookName then break end
		if spellName == spellBookName then
			local slotType = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)--SpellBookFrame.bookType)
			if slotType == "SPELL" then
				return i
			end
			return nil
		end
	end
	return nil
end

-- Get skill type (SPELL, PETACTION, FUTURESPELL, FLYOUT)
function Private.GetSkillType(spellID)
	local spellName = GetSpellInfo(spellID)
	if not spellName then return nil end
	local skillType, globalSpellID = GetSpellBookItemInfo(spellName)
	-- skill type: "SPELL", "PETACTION", "FUTURESPELL", "FLYOUT"
	if skillType == "SPELL" and globalSpellID == spellID then return skillType end
	return nil
end

-- Duplicate any object
function Private.DeepCopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return new_table
    end
    return _copy(object)
end

-- Remove from table by val
function Private.TRemoveByVal(tab, val)
	for k, v in pairs(tab) do
		if v == val then
			table.remove(tab, k)
			return true
		end
	end
	return false
end

-- Get spellID from spellName
local idCache = setmetatable({}, { -- This metatable takes 2Mb of memory
	-- Use weak references both for key and values
	__mode = 'kv', 
	-- This is called only if the key has not been found in the table
	__index = function(self, key)
		-- ID to check is stored in the table itself, so it can get GC'ed
		local id = rawget(self, '__id') or 0
		while id < 100000 do
			id = id + 1
			local name = GetSpellInfo(id)
			if name then
				-- Store any name we encounter, it may be of some use later
				self[name] = id
				if name == key then
					-- Stop the loop as soon as we have found the spell
					break
				end
			end
		end
		-- Remember where to start from next time
		rawset(self, '__id', id)
		-- Finally try to get the spell id
		return rawget(self, key)
	end
})
function Private.GetSpellID(name)
  return name and idCache[name]
end
