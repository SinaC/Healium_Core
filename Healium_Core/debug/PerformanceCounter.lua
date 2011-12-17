---------------------------------------------------------
-- PerformanceCounter

-- APIs:
-- PerformanceCounter:Increment(addonName, functionName): increment performance counter of functionName in addonName section
-- PerformanceCounter:Start(addonName, functionName): start timer
-- PerformanceCounter:Stop(addonName, functionName): stop timer and add stop - start to total CPU
-- PerformanceCounter:Get(addonName, functionName): get performance counter of functionName or all performance counters in addonName section
-- PerformanceCounter:Reset(): reset performance counters

local H, C, L = unpack(select(2, ...))

-- Namespace
H.PerformanceCounter = {}

-- Aliases
local PerformanceCounter = H.PerformanceCounter

-- Local variables
local LastReset = GetTime()
local counters = {}

function PerformanceCounter:Increment(addonName, fctName)
	local currentTime = GetTime()
	local addonSection = counters[addonName]
	if not addonSection then
		counters[addonName] = {}
		addonSection = counters[addonName]
	end
	local entry = addonSection[fctName]
	if not entry then
		addonSection[fctName] = {count = 1, lastTime = GetTime()}
	else
		local cnt = (entry.count or 0) + 1
		local diff = currentTime - (entry.lastTime or currentTime)
		local lowestDiff = entry.lowestSpan or 999999
		if diff < lowestDiff then lowestDiff = diff end
		local highestDiff = entry.highestSpan or 0
		if diff > highestDiff then highestDiff = diff end
		entry.count = cnt
		entry.lastTime = currentTime
		entry.lowestSpan = lowestDiff
		entry.highestSpan = highestDiff
	end
end

function PerformanceCounter:Start(addonName, fctName)
	local currentTime = GetTime()
	local addonSection = counters[addonName]
	if not addonSection then
		counters[addonName] = {}
		addonSection = counters[addonName]
	end
	local entry = addonSection[fctName]
	if not entry then
		addonSection[fctName] = {cpuCount = 1, start = currentTime}
	else
		local cnt = (entry.cpuCount or 0) + 1
		entry.cpuCount = cnt
		--entry.start = currentTime
		entry.start = (entry.start or 0) + currentTime
	end
end

function PerformanceCounter:Stop(addonName, fctName)
	local currentTime = GetTime()
	local addonSection = counters[addonName]
	if not addonSection then
		counters[addonName] = {}
		addonSection = counters[addonName]
	end
	local entry = addonSection[fctName]
	assert(entry, "PerformanceCounter "..tostring(fctName).." stopped before being started")
	assert(entry.start, "PerformanceCounter "..tostring(fctName).." stopped before being started")
	--local totalCPUTime = (entry.cpuTime or 0) + (currentTime - entry.start)
	--entry.cpuTime = totalCPUTime
	entry.stop = (entry.stop or 0) + currentTime
	--entry.start = 0 -- reset
end

function PerformanceCounter:Get(addonName, fctName)
	if not addonName then return nil end
	local addonEntry = counters[addonName]
	if not addonEntry then return nil end
	if not fctName then
		local timespan = GetTime() - LastReset
		local list = {} -- make a copy to avoid caller modifying counters
		for key, value in pairs(addonEntry) do
			--print(key.."->"..tostring(value.count).."  "..tostring(value.lastTime).."  "..tostring(value.lowestSpan).."  "..tostring(value.highestSpan))
			--list[key] = {count = value.count, lastTime = value.lastTime, lowestSpan = value.lowestSpan, highestSpan = value.highestSpan, frequency = count / timespan}
			list[key] = {count = value.count, frequency = value.count and (value.count / timespan), lowestSpan = value.lowestSpan, cpuCount = value.cpuCount, cpuTime = value.stop and (value.stop - value.start)}
		end
		return list
	else
		local entry = addonEntry[fctName]
		if entry then
			--return {count = entry.count, lastTime = entry.lastTime, lowestSpan = entry.lowestSpan, highestSpan = entry.highestSpan}
			return {count = value.count, frequency = value.count / timespan, lowestSpan = value.lowestSpan, cpuCount = value.cpuCount, cpuTime = value.cpuTime}
		else
			return nil
		end
	end
end

function PerformanceCounter:Reset(addonName)
	LastReset = GetTime()
	if not addonName then
		for addon, _ in pairs(counters) do
			PerformanceCounter:Reset(addon)
		end
	else
		-- local addonEntry = counters[addonName]
		-- if not addonEntry then return end
		-- for key, _ in pairs(addonEntry) do
			-- addonEntry[key] = {}
		-- end
		counters[addonName] = {}
	end
end