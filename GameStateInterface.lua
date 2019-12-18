-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

--~ Conditional checking; GameState updates and retreival; Manages SavedVaraibles

-- TODO The tables in this file are intended to be local, but this goes against simplistic segment conditionals, because we require global get functions stated in them to access locals.
-- TODO Because we can't require files, all functions and tables accessed from the function strings of segment lengths or segment conditionals need to be local to the GameStateInterface. Ideally, segments will eventually contain their own language, with keywords such that statements like "thisSpell.charges UP" and "auraPet.timeRemaining < 5" are possible. Then we can move evaulation code to an EvaluationLibrary--listing the functions available to conditionals--which would perform the rules interpretation.
-- TODO Spells data could be generated automatically, however the segement data would need a way to indicate which unit the spell will be cast from/cast on. And a lot of spellIds in spellbooks do not indicate the same spell as a buff applied.
-- TODO Spell Cooldowns should only be check from a registry of spells we know are on cooldown, based on the combat log

--- Flags --
--
AQ.SOUND_PATH = "path"
AQ.SOUND_FUNC = "func"
AQ.SOUND_PATH_PREFIX = "path::"
AQ.SOUND_FUNC_PREFIX = "func::"
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

AQ.spells = nil
AQ.events = nil
AQ.segments = nil
AQ.spellsSnapshot = nil

AQ.GS = {} -- A table for custom segment stored values

local type = type
local pairs = pairs
local loadstring = loadstring

local Frame_SpellCooldownTicker = CreateFrame("Frame", "AQ:SPELL_COOLDOWNS")
local spellsOnCooldown = {}

-------- SaveSpellSnapshot()
local function SaveSpellSnapshot(spellId)
	if AQ.spellsSnapshot[spellId] == nil then AQ.spellsSnapshot[spellId] = {} end
	
	for n=1,#AQ.spells[spellId],1 do
		AQ.spellsSnapshot[spellId][n] = AQ.spells[spellId][n]
	end
end

-- Overlap? Track that spell on pet, track same spell on player??
local function AmmendSpells(spellsAmmending)
	for spellId,spellData in pairs(spellsAmmending) do
		AQ.spells[spellId] = spellData
	end
end

local function AmmendEvents(eventsAmmending)
	for eventId,arr in pairs(eventsAmmending) do
		if AQ.events[eventId] == nil then
			AQ.events[eventId] = {}
		end
		
		local sizeEventIdArray = #(AQ.events[eventId])
		for i,eventData in ipairs(arr) do
			AQ.events[eventId][sizeEventIdArray + i] = eventData
		end
	end
end

local function AmmendSegments(segmentsAmmending)
	for segmentId,arr in pairs(segmentsAmmending) do
		if AQ.segments[segmentId] == nil then
			AQ.segments[segmentId] = {}
		end
		
		local sizeSegmentIdArray = #(AQ.segments[segmentId])
		for i,segmentsTbl in ipairs(arr) do
			AQ.segments[segmentId][sizeSegmentIdArray + i] = segmentsTbl
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
if AQ.VERBOSE then print("Error in conditional string: '", (type(cond) == "string" and cond or result), "'") end 
		AQ.LogError({code=AQ.ERR_CUSTOM_FUNCTION_RUNTIME}, "FunctionEval()", "", (type(cond) == "string" and cond or result) )
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
						AQ.ProcessSpell(thisSpellId, currTime) -- Will kill frame for us. -- TODO Potential enless loop for errors
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

-------- AQ.GSI_RemoveExtension()
function AQ.GSI_RemoveExtension(specId, extName)
	if SV_Specializations[specId][extName] == nil then 
		return false
	else
		SV_Specializations[specId][extName] = nil
		return true
	end
end

-------- AQ.GSI_ResetAudioQs
function AQ.GSI_ResetAudioQs()
	SV_Specializations = {}
end

-------- AQ.GSI_EvaluateLength()
function AQ.GSI_EvaluateLength(prompt, promptIndex)
	if prompt == nil or promptIndex == nil then 
		error({code=AQ.ERR_INVALID_ARGS, func="AQ.GSI_EvaluateSound(prompt="..AQ.Printable(prompt)..", promptIndex="..AQ.Printable(promptIndex)..")"})
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
		error({code=AQ.ERR_INVALID_CONDITIONAL_RESULT, func="GSI_EvaluateLength(length = "..(length == nil and "nil" or length).." type:"..type(length)..")"})
	end
end

-------- AQ.GSI_EvaluateSound()
function AQ.GSI_EvaluateSound(prompt, promptIndex) -- TODO Memoize soundPaths[(sounds_root_cut)"folder/folder/.../filename"(extension cut)] = "full/file/path.ogg"
	if prompt == nil or promptIndex == nil then 
		error({code=AQ.ERR_INVALID_ARGS, func="AQ.GSI_EvaluateSound(prompt="..AQ.Printable(prompt)..", promptIndex="..AQ.Printable(promptIndex)..")"})
	end
	local sound = prompt[promptIndex]

	local t = type(sound)
	if t == "function" then
		return FunctionEval(sound)
	elseif t == "number" then
		return sound
	elseif t == "string" then 
		local split = AQ.SplitString(sound, "::")
		if #split == 1 then
			return sound
		elseif #split == 2 then		
			if split[1] == AQ.SOUND_PATH and split[2] ~= nil then
				return split[2]
			elseif split[1] == AQ.SOUND_FUNC and split[2] ~= nil then
				local eval, func = FunctionEval(split[2])
				prompt[promptIndex] = func 
				return eval
			end
		end
	end
	return nil
end

-------- AQ.GSI_EvaluateConditional()
function AQ.GSI_EvaluateConditional(prompt, promptIndex)
	if prompt == nil or promptIndex == nil then
		error({code=AQ.ERR_INVALID_ARGS, func="AQ.GSI_EvaluateConditional(prompt="..AQ.Printable(prompt)..", promptIndex="..AQ.Printable(promptIndex)..")"})
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

-------- AQ.GSI_UpdateSpellTable()
function AQ.GSI_UpdateSpellTable(spellId, cdDur, cdExpiration)
	if AQ.spells[spellId] == nil then
		error({code=AQ.ERR_UNKNOWN_SPELL_AS_ARGUMENT, func="AQ.GSI_UpdateSpellTable() spellId="..(spellId~=nil and spellId or "nil").." cdDur="..(cdDur~=nil and cdDur or "nil").." cdExpiration="..(cdExpiration~=nil and cdExpiration or "nil")})
	end
	local thisSpell = AQ.spells[spellId]
	
	if cdDur == nil or cdExpiration == nil then
if AQ.DEBUG then if cdDur~=cdExpiration then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."GSI_UpdateSpellTable(): - "..(cdDur == nil and "cdDur" or "cdExpiration").." was sole nil passed.") end end
		local start, dur = GetSpellCooldown(spellId)
		cdDur = dur
		cdExpiration = start + dur
	end
	
	if (thisSpell[AQ.SPELL_SPELL_TYPE] == AQ.SPELL_TYPE_AURA and thisSpell[AQ.SPELL_EXPIRATION] ~= cdExpiration) or
			(thisSpell[AQ.SPELL_SPELL_TYPE] == AQ.SPELL_TYPE_ABILITY and (thisSpell[AQ.SPELL_CHARGES] ~= GetSpellCharges(spellId) or thisSpell[AQ.SPELL_EXPIRATION] ~= cdExpiration)) then
		SaveSpellSnapshot(spellId)
		thisSpell[AQ.SPELL_CHARGES] = GetSpellCharges(spellId)
		local isChargeSpell = thisSpell[AQ.SpellCharges] ~= nil
		
		if not (cdDur > 0 and AQ.IsEqualToGcd(cdDur)) then
			thisSpell[AQ.SPELL_DURATION] = cdDur
			thisSpell[AQ.SPELL_EXPIRATION] = cdExpiration
			
			FrameInitOrUpdateExpiration(spellId, cdExpiration)
			
			if isChargeSpell and thisSpell[AQ.SPELL_CHARGES] == AQ.spellsSnapshot[spellId][AQ.SPELL_CHARGES] then -- TODO Let the charge send the AttemptStartPrompt() instead. Also, trash code. Should be higher-level determined.
				return false
			end
		end
		
		return true
	end
	return false
end

-------- AQ.GSI_UpdateAllSpellTables()
function AQ.GSI_UpdateAllSpellTables(init)
	for spellId,spell in pairs(AQ.spells) do
		local cdStart, cdDur = GetSpellCooldown(spellId)
		local cdExpiration = cdStart + cdDur
		
		AQ.GSI_UpdateSpellTable(spellId, cdDur, cdExpiration)
		if init then 
			SaveSpellSnapshot(spellId)
		end
	end
end

-------- AQ.GSI_UpdateEventTable(event)
function AQ.GSI_UpdateEventTable(event, ...)
	if AQ.events[event] == nil then
		error({code=AQ.ERR_UNKNOWN_EVENT_AS_ARGUMENT, func="AQ.GSI_UpdateEventTable(event="..(event~=nil and event or "nil")..")"})
	end
	
	local args = {...}
	if ... ~= nil then
		for n=1,#args,1 do
			AQ.events[event][n] = args[n]
		end
	end
end

-------- AQ.GSI_GetSpell()
function AQ.GSI_GetSpell(spellId)
	return AQ.spells[spellId]
end

-------- AQ.GSI_GetSpellsTable()
function AQ.GSI_GetSpellsTable()
	return AQ.spells
end

-------- AQ.GSI_GetSegmentsTable()
function AQ.GSI_GetSegmentsTable()
	return AQ.segments
end

-------- AQ.GSI_GetSpellsSnapshotTable()
function AQ.GSI_GetSpellsSnapshotTable()
	return AQ.spellsSnapshot
end

-------- AQ.GetAuraInfo() -- I don't want stuff like this under the "GSI_" prefix, because it does not pertain to performing operations on the AudioQ GameState data. It only performs the operation of retreival for a particular peice of information straight from the blizAPI. Having it in the GSI file is only a consequence of not having a more intricate function string parser.
function AQ.GetAuraInfo(unitId, spellId, spellType)
	for n=1,40,1 do
		local auraSpellId = select(AQ.UNIT_AURA_SPELL_ID, UnitAura(unitId, n, spellType))
		if auraSpellId == nil then 
			return nil
		elseif auraSpellId == spellId then
			return UnitAura(unitId, n, spellType)
		end
	end
end

-------- AQ.GSI_AuraIsIncluded()
function AQ.GSI_AuraIsIncluded(spellId)
	return false ~= (AQ.spells ~= nil and AQ.spells[spellId] and AQ.spells[spellId][AQ.SPELL_SPELL_TYPE] == AQ.SPELL_TYPE_AURA or false)
end

-------- AQ.GSI_SpellIsIncluded()
function AQ.GSI_SpellIsIncluded(spellId)
	return AQ.spells[spellId] ~= nil and #AQ.spells[spellId] > 0
end

-------- AQ.GSI_SpecHasPrompts()
function AQ.GSI_SpecHasPrompts(specIdToCheck)
	return false ~= (SV_Specializations ~= nil and SV_Specializations[specIdToCheck] and not AQ.TableEmpty(SV_Specializations[specIdToCheck]) or false)
end

-------- AQ.GSI_RegisterCustomEvents()
function AQ.GSI_RegisterCustomEvents(frame)
if AQ.VERBOSE then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."Registering custom AQ.events:") end
	for event,_ in pairs(AQ.events) do
		frame:RegisterEvent(event)
if AQ.VERBOSE then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."- "..event) end
	end
end

-------- AQ.GSI_UnregisterCustomEvents()
function AQ.GSI_UnregisterCustomEvents(frame)
	frame:UnregisterAllEvents()
end

-------- AQ.GSI_EventIsIncluded()
function AQ.GSI_EventIsIncluded(eventToCheck)
	return AQ.events[eventToCheck] ~= nil
end

-------- AQ.GSI_LoadSpecTables(specId)
function AQ.GSI_LoadSpecTables(specId, funcsForLoading)
	AQ.spellsSnapshot = {}
	
	if SV_Specializations == nil and funcsForLoading == nil then
	-- Nothing to load
		return false
	end
	if type(funcsForLoading) == "table" then
		InitializeAndLoadExtension(specId, funcsForLoading)
	end
	
	if SV_Specializations[specId] ~= nil and not AQ.TableEmpty(SV_Specializations[specId]) then
		if AQ.spells == nil then AQ.spells = {} else wipe(AQ.spells) end
		if AQ.events == nil then AQ.events = {} else wipe(AQ.events) end
		if AQ.segments == nil then AQ.segments = {} else wipe(AQ.segments) end
		for extName,_ in pairs(SV_Specializations[specId]) do
			local thisExtFuncs = AQ.GetExtensionFuncs(extName)
if AQ.DEBUG then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."  Loading EXT: "..extName) end
			AmmendTables(thisExtFuncs["GetSpells"](), thisExtFuncs["GetEvents"](), thisExtFuncs["GetSegments"]())
			thisExtFuncs["Initialize"]()
		end
		
		RemoveUntrackedSpells(AQ.spells)
		return true
	end
	do -- Spec has no loaded Extensions
		AQ.WipePrompts()
		RemoveAllTrackedSpells()
	end
	return false
end
