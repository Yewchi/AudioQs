-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

--~ Conditional checking; GameState updates and retreival; Manages SavedVaraibles

-- TODO The tables in this file are intended to be local, but this goes against simplistic segment conditionals, because we require global get functions stated in them to access locals.
-- TODO Because we can't require files, all functions and tables accessed from the function strings of segment lengths or segment conditionals need to be local to the GameStateInterface. Ideally, segments will eventually contain their own language, with keywords such that statements like "thisSpell.charges UP" and "auraPet.timeRemaining < 5" are possible. Then we can move evaulation code to an EvaluationLibrary--listing the functions available to conditionals--which would perform the rules interpretation.
-- TODO Spells data could be generated automatically, however the segement data would need a way to indicate which unit the spell will be cast from/cast on. And a lot of spellIds in spellbooks do not indicate the same spell as a buff applied.
-- TODO Spell Cooldowns should only be check from a registry of spells we know are on cooldown, based on the combat log

--- Flags --
--
AUDIOQS.SOUND_PATH = "path"
AUDIOQS.SOUND_FUNC = "func"
AUDIOQS.SOUND_PATH_PREFIX = "path::"
AUDIOQS.SOUND_FUNC_PREFIX = "func::"
--
-- /Flags --

------- Table key references --
--
local ON_COOLDOWN_SPELLID = 1
local ON_COOLDOWN_CDEXPIRATION = 2
--
------ /Table key references --

------- Static vals --
--
local BAD_SPELL_LIMITER_TIME = 0.08333

--
------- /Static vals --

AUDIOQS.spells = nil
AUDIOQS.events = nil
AUDIOQS.segments = nil
AUDIOQS.spellsSnapshot = nil

AUDIOQS.GS = {} -- A table for custom segment stored values

local type = type
local pairs = pairs
local loadstring = loadstring

local Frame_SpellCooldownTicker = CreateFrame("Frame", "AQ:SPELL_COOLDOWNS")
local spellsOnCooldown = {}

-------- SaveSpellSnapshot()
local function SaveSpellSnapshot(spellId)
	if AUDIOQS.spellsSnapshot[spellId] == nil then AUDIOQS.spellsSnapshot[spellId] = {} end
	
	for n=1,#AUDIOQS.spells[spellId],1 do
		AUDIOQS.spellsSnapshot[spellId][n] = AUDIOQS.spells[spellId][n]
	end
end

-- Overlap? Track that spell on pet, track same spell on player??
local function AmmendSpells(spellsAmmending)
	for spellId,spellData in pairs(spellsAmmending) do
		AUDIOQS.spells[spellId] = spellData
	end
end

local function AmmendEvents(eventsAmmending)
	for eventId,arr in pairs(eventsAmmending) do
		if AUDIOQS.events[eventId] == nil then
			AUDIOQS.events[eventId] = {}
		end
		
		local sizeEventIdArray = #(AUDIOQS.events[eventId])
		for i,eventData in ipairs(arr) do
			AUDIOQS.events[eventId][sizeEventIdArray + i] = eventData
		end
	end
end

local function AmmendSegments(segmentsAmmending)
	for segmentId,arr in pairs(segmentsAmmending) do
		if AUDIOQS.segments[segmentId] == nil then
			AUDIOQS.segments[segmentId] = {}
		end
		
		local sizeSegmentIdArray = #(AUDIOQS.segments[segmentId])
		for i,segmentsTbl in ipairs(arr) do
			AUDIOQS.segments[segmentId][sizeSegmentIdArray + i] = segmentsTbl
		end
	end
end

local function AmmendTables(spellsAmmending, eventsAmmending, segmentsAmmending)
	AmmendSpells(spellsAmmending)
	AmmendEvents(eventsAmmending)
	AmmendSegments(segmentsAmmending)
end

-------------- InitializeAndLoadExtension()
local function InitializeAndLoadExtension(specId, funcsForLoading, fullReset)
	if funcsForLoading == nil then return false end
	
	if SV_Specializations == nil then 
		SV_Specializations = {}
	end
	
	local extName = funcsForLoading["GetName"]()
	
	if fullReset or SV_Specializations[specId] == nil then 
		SV_Specializations[specId] = {}
	end
	if SV_Specializations[specId][extName] == nil then
		SV_Specializations[specId][extName] = true
	end
end

local function FunctionEval(cond)
	local f
	local neededLoad
	if type(cond) == "string" then
		neededLoad = true
		f = loadstring(cond)
	elseif type(cond) == "function" then
		neededLoad = false
		f = cond
	end
	local success, result = pcall(f)
	if not success then 
if AUDIOQS.VERBOSE then print("Error in conditional string: '", (type(cond) == "string" and cond or result), "'") end 
		AUDIOQS.LogError({code=AUDIOQS.ERR_CUSTOM_FUNCTION_RUNTIME}, "FunctionEval()", "", (type(cond) == "string" and cond or result) )
		result = nil
	end
	
	if neededLoad then
		return result, f
	else
		return result
	end
end

local function RemoveUntrackedSpells(spellsTbl)
	for i,arr in ipairs(spellsOnCooldown) do 
		if spellsTbl[arr[ON_COOLDOWN_SPELLID]] == nil then
			table.remove(spellsOnCooldown, i)
		end
	end
end

local function RemoveSpellOnCooldown(spellId) -- TODO Needs checks or needs safe code above?
	for n = 1, #spellsOnCooldown, 1 do
		if spellId == spellsOnCooldown[n][ON_COOLDOWN_SPELLID] then
			table.remove(spellsOnCooldown, n)
			break
		end
	end
	if #spellsOnCooldown == 0 then
		Frame_SpellCooldownTicker:SetScript("OnUpdate", nil)
	end
end

local function RemoveAllTrackedSpells()
	wipe(spellsOnCooldown or {})
	Frame_SpellCooldownTicker:SetScript("OnUpdate", nil)
end

local function AddSpellOnCooldown(spellId, cdExpiration)
	for n = 1, #spellsOnCooldown, 1 do
		if spellsOnCooldown[n][ON_COOLDOWN_SPELLID] == spellId then
			spellsOnCooldown[n][ON_COOLDOWN_CDEXPIRATION] = cdExpiration
			return
		end
	end
	table.insert(spellsOnCooldown, {[ON_COOLDOWN_SPELLID]=spellId, [ON_COOLDOWN_CDEXPIRATION] = cdExpiration})
end

local function FrameInitOrUpdateExpiration(spellId, cdExpiration)
	local frame = Frame_SpellCooldownTicker
	
	if cdExpiration > 0 then
		AddSpellOnCooldown(spellId, cdExpiration)
	elseif cdExpiration == 0 then
		RemoveSpellOnCooldown(spellId)
	end
	
	if frame:GetScript("OnUpdate") == nil then
		frame.limiter = BAD_SPELL_LIMITER_TIME
		frame:SetScript("OnUpdate", 
			function(_, elapsed)
				frame.limiter = frame.limiter - elapsed
				if frame.limiter > 0 then return end
				frame.limiter = BAD_SPELL_LIMITER_TIME
				local currTime = GetTime()
				local n = 1
				while n <= #spellsOnCooldown do
					local thisSpellOnCooldown = spellsOnCooldown[n]
					local thisSpellId = thisSpellOnCooldown[ON_COOLDOWN_SPELLID]
					local thisCdExpiration = thisSpellOnCooldown[ON_COOLDOWN_CDEXPIRATION]
					if currTime > thisCdExpiration then
						AUDIOQS.ProcessSpell(thisSpellId, currTime) -- Will kill frame for us. -- TODO Potential enless loop for errors
						if n <= #spellsOnCooldown and thisSpellId == spellsOnCooldown[n][ON_COOLDOWN_SPELLID] then
								n = n + 1
						end
					else
						n = n + 1
					end
				end
			end
		)
	end
end

-------- AUDIOQS.GSI_RemoveExtension()
function AUDIOQS.GSI_RemoveExtension(specId, extName)
	if SV_Specializations[specId][extName] == nil then 
		return false
	else
		SV_Specializations[specId][extName] = nil
		return true
	end
end

-------- AUDIOQS.GSI_ResetAudioQs
function AUDIOQS.GSI_ResetAudioQs()
	SV_Specializations = {}
end

-------- AUDIOQS.GSI_EvaluateLength()
function AUDIOQS.GSI_EvaluateLength(prompt, promptIndex)
	if prompt == nil or promptIndex == nil then 
		error({code=AUDIOQS.ERR_INVALID_ARGS, func="AUDIOQS.GSI_EvaluateSound(prompt="..AUDIOQS.Printable(prompt)..", promptIndex="..AUDIOQS.Printable(promptIndex)..")"})
	end
	local length = prompt[promptIndex]
	
	local t = type(length)
	if t == "function" then
		local eval = FunctionEval(length)
		return (eval ~= nil and eval or 0.0)
	elseif t == "number" then
		return length
	elseif t == "string" then
		local eval, func = FunctionEval(length)
		prompt[promptIndex] = func 
		if type(eval) == "number" then
			return eval
		else
			return 0.0
		end
	elseif t == "nil" then
		return 0.0
	else
		error({code=AUDIOQS.ERR_INVALID_CONDITIONAL_RESULT, func="GSI_EvaluateLength(length = "..(length == nil and "nil" or length).." type:"..type(length)..")"})
	end
end

-------- AUDIOQS.GSI_EvaluateSound()
function AUDIOQS.GSI_EvaluateSound(prompt, promptIndex) -- TODO Memoize soundPaths[(sounds_root_cut)"folder/folder/.../filename"(extension cut)] = "full/file/path.ogg"
	if prompt == nil or promptIndex == nil then 
		error({code=AUDIOQS.ERR_INVALID_ARGS, func="AUDIOQS.GSI_EvaluateSound(prompt="..AUDIOQS.Printable(prompt)..", promptIndex="..AUDIOQS.Printable(promptIndex)..")"})
	end
	local sound = prompt[promptIndex]

	local t = type(sound)
	if t == "function" then
		return FunctionEval(sound)
	elseif t == "number" then
		return sound
	elseif t == "string" then 
		local split = AUDIOQS.SplitString(sound, "::")
		if #split == 1 then
			return sound
		elseif #split == 2 then		
			if split[1] == AUDIOQS.SOUND_PATH and split[2] ~= nil then
				return split[2]
			elseif split[1] == AUDIOQS.SOUND_FUNC and split[2] ~= nil then
				local eval, func = FunctionEval(split[2])
				prompt[promptIndex] = func 
				return eval
			end
		end
	end
	return nil
end

-------- AUDIOQS.GSI_EvaluateConditional()
function AUDIOQS.GSI_EvaluateConditional(prompt, promptIndex)
	if prompt == nil or promptIndex == nil then
		error({code=AUDIOQS.ERR_INVALID_ARGS, func="AUDIOQS.GSI_EvaluateConditional(prompt="..AUDIOQS.Printable(prompt)..", promptIndex="..AUDIOQS.Printable(promptIndex)..")"})
	end
	local conditional = prompt[promptIndex]

	if type(conditional) == "function" then 
		return FunctionEval(conditional)
	elseif type(conditional) == "string" then
		local eval, func = FunctionEval(conditional)
		prompt[promptIndex] = func
		return eval
	end
	return conditional == true
end

-------- AUDIOQS.GSI_UpdateSpellTable()
function AUDIOQS.GSI_UpdateSpellTable(spellId, cdDur, cdExpiration)
	if AUDIOQS.spells[spellId] == nil then
		error({code=AUDIOQS.ERR_UNKNOWN_SPELL_AS_ARGUMENT, func="AUDIOQS.GSI_UpdateSpellTable() spellId="..(spellId~=nil and spellId or "nil").." cdDur="..(cdDur~=nil and cdDur or "nil").." cdExpiration="..(cdExpiration~=nil and cdExpiration or "nil")})
	end
	local thisSpell = AUDIOQS.spells[spellId]
	
	if cdDur == nil or cdExpiration == nil then
if AUDIOQS.DEBUG then if cdDur~=cdExpiration then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."GSI_UpdateSpellTable(): - "..(cdDur == nil and "cdDur" or "cdExpiration").." was sole nil passed.") end end
		local start, dur = GetSpellCooldown(spellId)
		cdDur = dur
		cdExpiration = start + dur
	end
	
	if (thisSpell[AUDIOQS.SPELL_SPELL_TYPE] == AUDIOQS.SPELL_TYPE_AURA and thisSpell[AUDIOQS.SPELL_EXPIRATION] ~= cdExpiration) or
			(thisSpell[AUDIOQS.SPELL_SPELL_TYPE] == AUDIOQS.SPELL_TYPE_ABILITY and (thisSpell[AUDIOQS.SPELL_CHARGES] ~= GetSpellCharges(spellId) or thisSpell[AUDIOQS.SPELL_EXPIRATION] ~= cdExpiration)) then
		SaveSpellSnapshot(spellId)
		thisSpell[AUDIOQS.SPELL_CHARGES] = GetSpellCharges(spellId)
		local isChargeSpell = thisSpell[AUDIOQS.SpellCharges] ~= nil
		
		if not (cdDur > 0 and AUDIOQS.IsEqualToGcd(cdDur)) then
			thisSpell[AUDIOQS.SPELL_DURATION] = cdDur
			thisSpell[AUDIOQS.SPELL_EXPIRATION] = cdExpiration
			
			FrameInitOrUpdateExpiration(spellId, cdExpiration)
			
			if isChargeSpell and thisSpell[AUDIOQS.SPELL_CHARGES] == AUDIOQS.spellsSnapshot[spellId][AUDIOQS.SPELL_CHARGES] then -- TODO Let the charge send the AttemptStartPrompt() instead. Also, trash code. Should be higher-level determined.
				return false
			end
		end
		
		return true
	end
	return false
end

-------- AUDIOQS.GSI_UpdateAllSpellTables()
function AUDIOQS.GSI_UpdateAllSpellTables(init)
	for spellId,spell in pairs(AUDIOQS.spells) do
		local cdStart, cdDur = GetSpellCooldown(spellId)
		local cdExpiration = cdStart + cdDur
		
		AUDIOQS.GSI_UpdateSpellTable(spellId, cdDur, cdExpiration)
		if init then 
			SaveSpellSnapshot(spellId)
		end
	end
end

-------- AUDIOQS.GSI_UpdateEventTable(event)
function AUDIOQS.GSI_UpdateEventTable(event, ...)
	if AUDIOQS.events[event] == nil then
		error({code=AUDIOQS.ERR_UNKNOWN_EVENT_AS_ARGUMENT, func="AUDIOQS.GSI_UpdateEventTable(event="..(event~=nil and event or "nil")..")"})
	end
	
	local args = {...}
	if ... ~= nil then
		for n=1,#args,1 do
			AUDIOQS.events[event][n] = args[n]
		end
	end
end

-------- AUDIOQS.GSI_GetSpell()
function AUDIOQS.GSI_GetSpell(spellId)
	return AUDIOQS.spells[spellId]
end

-------- AUDIOQS.GSI_GetSpellsTable()
function AUDIOQS.GSI_GetSpellsTable()
	return AUDIOQS.spells
end

-------- AUDIOQS.GSI_GetSegmentsTable()
function AUDIOQS.GSI_GetSegmentsTable()
	return AUDIOQS.segments
end

-------- AUDIOQS.GSI_GetSpellsSnapshotTable()
function AUDIOQS.GSI_GetSpellsSnapshotTable()
	return AUDIOQS.spellsSnapshot
end

-------- AUDIOQS.GSI_AuraIsIncluded()
function AUDIOQS.GSI_AuraIsIncluded(spellId)
	return false ~= (AUDIOQS.spells ~= nil and AUDIOQS.spells[spellId] and AUDIOQS.spells[spellId][AUDIOQS.SPELL_SPELL_TYPE] == AUDIOQS.SPELL_TYPE_AURA or false)
end

-------- AUDIOQS.GSI_SpellIsIncluded()
function AUDIOQS.GSI_SpellIsIncluded(spellId)
	return AUDIOQS.spells[spellId] ~= nil and #AUDIOQS.spells[spellId] > 0
end

-------- AUDIOQS.GSI_SpecHasPrompts()
function AUDIOQS.GSI_SpecHasPrompts(specIdToCheck)
	return false ~= (SV_Specializations ~= nil and SV_Specializations[specIdToCheck] and not AUDIOQS.TableEmpty(SV_Specializations[specIdToCheck]) or false)
end

-------- AUDIOQS.GSI_RegisterCustomEvents()
function AUDIOQS.GSI_RegisterCustomEvents(frame)
if AUDIOQS.VERBOSE then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Registering custom AUDIOQS.events:") end
	for event,_ in pairs(AUDIOQS.events) do
		frame:RegisterEvent(event)
if AUDIOQS.VERBOSE then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."- "..event) end
	end
end

-------- AUDIOQS.GSI_UnregisterCustomEvents()
function AUDIOQS.GSI_UnregisterCustomEvents(frame)
	frame:UnregisterAllEvents()
end

-------- AUDIOQS.GSI_EventIsIncluded()
function AUDIOQS.GSI_EventIsIncluded(eventToCheck)
	return AUDIOQS.events[eventToCheck] ~= nil
end

-------- AUDIOQS.GSI_LoadSpecTables(specId)
function AUDIOQS.GSI_LoadSpecTables(specId, funcsForLoading)
	AUDIOQS.spellsSnapshot = {}
	
	if SV_Specializations == nil and funcsForLoading == nil then
	-- Nothing to load
		return false
	end
	if type(funcsForLoading) == "table" then
		InitializeAndLoadExtension(specId, funcsForLoading)
	end
	
	if SV_Specializations[specId] ~= nil and not AUDIOQS.TableEmpty(SV_Specializations[specId]) then
		if AUDIOQS.spells == nil then AUDIOQS.spells = {} else wipe(AUDIOQS.spells) end
		if AUDIOQS.events == nil then AUDIOQS.events = {} else wipe(AUDIOQS.events) end
		if AUDIOQS.segments == nil then AUDIOQS.segments = {} else wipe(AUDIOQS.segments) end
		for extName,_ in pairs(SV_Specializations[specId]) do
			local thisExtFuncs = AUDIOQS.GetExtensionFuncs(extName)
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."  Loading EXT: "..extName) end
			AmmendTables(thisExtFuncs["GetSpells"](), thisExtFuncs["GetEvents"](), thisExtFuncs["GetSegments"]())
			thisExtFuncs["Initialize"]()
		end
		
		RemoveUntrackedSpells(AUDIOQS.spells)
		return true
	end
	do -- Spec has no loaded Extensions
		AUDIOQS.WipePrompts()
		RemoveAllTrackedSpells()
	end
	return false
end
