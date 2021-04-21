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
local FOURTY_NINE_DAYS = 2^22 -- 19/11/2020 Dispels use a charge counter to provide the functionality of keeping a dispel off-cd when it does not remove a debuff. The start time of the charge counter is 2^22 + 100,655. Probably something to do with 22 bits of precision in a 32-bit float (or something like that). When casting dispels, the bottom values on this adjust by larger-than-cooldown, sub 100 numbers, indiciating the bottom of this value could store the flag of the state of the dispel, which they've set up in an extended spell-type.
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
local spellsOnCooldownLastGcdAllowable = {}  -- If a spell cooldown goes up from a gcdExpiration to gcdExpiration + currGcd, it is off cooldown (or 1 in a billion chance it is recurrently having some other game mechanic timer added to it, while under the GCD)

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
			spellsOnCooldownLastGcdAllowable[spellId] = nil
			break
		end
	end
	if #spellsOnCooldown == 0 then
		Frame_SpellCooldownTicker:SetScript("OnUpdate", nil)
	end
end

local function RemoveAllTrackedSpells()
	wipe(spellsOnCooldown or {})
	wipe(spellsOnCooldownLastGcdAllowable or {})
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

local function SpellCooldownBlasterCannon(_, elapsed)
	Frame_SpellCooldownTicker.limiter = Frame_SpellCooldownTicker.limiter - elapsed
	if Frame_SpellCooldownTicker.limiter > 0 then return end
	Frame_SpellCooldownTicker.limiter = BAD_SPELL_LIMITER_TIME
	local currTime = GetTime()
	local n = 1
	local gcdExpiration = AUDIOQS.GetGcdExpiration()
	while n <= #spellsOnCooldown do
		local thisSpellOnCooldown = spellsOnCooldown[n]
		local thisSpellId = thisSpellOnCooldown[ON_COOLDOWN_SPELLID]
		local cdStart, cdDur = GetSpellCooldown(thisSpellId)
		local thisCdExpiration = cdStart + cdDur
		local previousCdExpiration = thisSpellOnCooldown[ON_COOLDOWN_CDEXPIRATION]

		if spellsOnCooldownLastGcdAllowable[thisSpellId] ~= nil or 
				(spellsOnCooldownLastGcdAllowable[thisSpellId] == nil and gcdExpiration ~= 0 and gcdExpiration == thisCdExpiration) then
			if spellsOnCooldownLastGcdAllowable[thisSpellId] == nil then
				--if thisSpellId == 19574 then  print("SpellCooldownBlasterCannon previousCdExpiration:", previousCdExpiration, "; gcdExpiration:", gcdExpiration) end
				if previousCdExpiration < gcdExpiration then -- The spell has increased it's cdExpiration upon duping the gcd, it's probably really ending at it's original time.
					spellsOnCooldownLastGcdAllowable[thisSpellId] = previousCdExpiration
					thisSpellOnCooldown[ON_COOLDOWN_CDEXPIRATION] = previousCdExpiration
					--if thisSpellId == 19574 then print("SpellCooldownBlasterCannon overriding GCD to previousCdExpiration:", AUDIOQS.PrintableTable(spellsOnCooldown[n])) end				
				else -- The spell cooldown has been reduced to mimic the gcd, unknown when from now til gcd end it really comes off cd. Call at GCD drop. (Random differentiation would actually provide a spread of the audio clog if all CDs are reset at once, alternatively, if all audio files were measured, a "Step-By-Step" call-out option could be given for spell cooldowns.
					spellsOnCooldownLastGcdAllowable[thisSpellId] = gcdExpiration
					thisSpellOnCooldown[ON_COOLDOWN_CDEXPIRATION] = gcdExpiration
					--if thisSpellId == 19574 then print("SpellCooldownBlasterCannon setting final allowable GCD:", AUDIOQS.PrintableTable(spellsOnCooldown[n])) end				
				end
			elseif currTime > spellsOnCooldownLastGcdAllowable[thisSpellId] then -- Doesn't account for haste differences
				--if thisSpellId == 19574 then print(string.format("<%f>", GetTime()), "SpellCooldownBlasterCannon final GCD chance taken:", AUDIOQS.PrintableTable(spellsOnCooldown[n])) end
				AUDIOQS.ProcessSpell(thisSpellId, currTime)
			end
		elseif thisSpellOnCooldown[ON_COOLDOWN_FIRST_ALLOWABLE_GCD] == nil and currTime > thisCdExpiration+0.15 then
			--if thisSpellId == 19574 then print("SpellCooldownBlasterCannon killing", AUDIOQS.PrintableTable(spellsOnCooldown[n])) end
			AUDIOQS.ProcessSpell(thisSpellId, currTime) -- Will kill frame for us. -- TODO Potential endless loop if there are programmer logic decision failings in numerical checks/comparisons. Especially, GSI_UpdateSpellTable must be a brick wall
		else
			thisSpellOnCooldown[ON_COOLDOWN_CDEXPIRATION] = thisCdExpiration -- code works if this is taken out of else, GSI_GscGcdOverride() will ignore if lastGcdAllowable was set
		end
		n = n + 1 -- Removed strange conditional n++. Probably vestigial through edits
	end
end

local function FrameInitOrUpdateExpiration(spellId, cdExpiration)
	if cdExpiration > 0 then
		AddSpellOnCooldown(spellId, cdExpiration)
		
		if Frame_SpellCooldownTicker:GetScript("OnUpdate") == nil then
			Frame_SpellCooldownTicker.limiter = BAD_SPELL_LIMITER_TIME
			Frame_SpellCooldownTicker:SetScript("OnUpdate", SpellCooldownBlasterCannon)
		end
	elseif cdExpiration == 0 then
		RemoveSpellOnCooldown(spellId)
	end
end

local getSpellCooldown1, getSpellCooldown2, getSpellCooldown3, getSpellCooldown4
-------- AUDIOQS.GSI_GetSpellCooldownGcdOverride()
function AUDIOQS.GSI_GetSpellCooldownGcdOverride(spellId)
	getSpellCooldown1, getSpellCooldown2, getSpellCooldown3, getSpellCooldown4 = GetSpellCooldown(spellId)
	if spellsOnCooldownLastGcdAllowable[spellId] and GetTime() >= spellsOnCooldownLastGcdAllowable[spellId] then -- this if has the requirement that the LastGcdAllowable[spellId] is correctly removed after adjusting spell cooldown data
		return 0, 0, getSpellCooldown3, getSpellCooldown4
	end
	return getSpellCooldown1, getSpellCooldown2, getSpellCooldown3, getSpellCooldown4
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

-------- AUDIOQS.GSI_UpdateSpellTable()
function AUDIOQS.GSI_UpdateSpellTable(spellId, cdDur, cdExpiration)
	if AUDIOQS.spells[spellId] == nil then
		error({code=AUDIOQS.ERR_UNKNOWN_SPELL_AS_ARGUMENT, func="AUDIOQS.GSI_UpdateSpellTable() spellId="..(spellId~=nil and spellId or "nil").." cdDur="..(cdDur~=nil and cdDur or "nil").." cdExpiration="..(cdExpiration~=nil and cdExpiration or "nil")})
	end
	local thisSpell = AUDIOQS.spells[spellId]
		
	if cdDur == nil or cdExpiration == nil then
if AUDIOQS.DEBUG then if cdDur~=cdExpiration then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."GSI_UpdateSpellTable(): - "..(cdDur == nil and "cdDur" or "cdExpiration").." was sole nil passed.") end end
		local start, dur = AUDIOQS.GSI_GetSpellCooldownGcdOverride(spellId)
		cdDur = dur
		cdExpiration = start + dur
	end
	
	local thisSpellCharges, _, fourtyNineCheck = GetSpellCharges(spellId)
	
	if ((fourtyNineCheck or 0) > FOURTY_NINE_DAYS and thisSpellCharges == 1 and cdExpiration > 0) then -- If a dispel has 1 charge, it is never on cd (but GetSpellCooldown may indicate cd expires after 8s if cast on undispelable target)
		cdExpiration = 0
		cdDur = 0
	end
	
	if (thisSpell[AUDIOQS.SPELL_SPELL_TYPE] == AUDIOQS.SPELL_TYPE_AURA and thisSpell[AUDIOQS.SPELL_EXPIRATION] ~= cdExpiration) or
			(thisSpell[AUDIOQS.SPELL_SPELL_TYPE] == AUDIOQS.SPELL_TYPE_ABILITY and (thisSpell[AUDIOQS.SPELL_CHARGES] ~= thisSpellCharges or thisSpell[AUDIOQS.SPELL_EXPIRATION] ~= cdExpiration)) then
		SaveSpellSnapshot(spellId)
		thisSpell[AUDIOQS.SPELL_CHARGES] = thisSpellCharges
		local isChargeSpell = thisSpell[AUDIOQS.SpellCharges] ~= nil
		
		if not (cdDur > 0 and AUDIOQS.IsEqualToGcd(cdDur)) then
			thisSpell[AUDIOQS.SPELL_DURATION] = cdDur
			thisSpell[AUDIOQS.SPELL_EXPIRATION] = cdExpiration
			
			if thisSpell[AUDIOQS.SPELL_SPELL_TYPE] == AUDIOQS.SPELL_TYPE_ABILITY then -- TODO Restrictive -- Indicates SCBC needs expanding
				FrameInitOrUpdateExpiration(spellId, cdExpiration) 
			end
			
			if isChargeSpell and thisSpell[AUDIOQS.SPELL_CHARGES] == AUDIOQS.spellsSnapshot[spellId][AUDIOQS.SPELL_CHARGES] then -- TODO Let the charge send the AttemptStartPrompt() instead. Also, trash code. Should be higher-level determined.
				return false
			end
			return true
		end
		return true --(removed, placed above to avoid redundant checks)
	end
	return false
end

-------- AUDIOQS.GSI_UpdateAllSpellTables()
function AUDIOQS.GSI_UpdateAllSpellTables(init)
	for spellId,spell in pairs(AUDIOQS.spells) do
		local cdStart, cdDur = AUDIOQS.GSI_GetSpellCooldownGcdOverride(spellId)
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
	
	if SV_Specializations[specId] ~= nil and not AUDIOQS.TableEmpty(SV_Specializations[specId]) then -- switch spec, or first load of spec
		if AUDIOQS.spells == nil then AUDIOQS.spells = {} else wipe(AUDIOQS.spells) end
		if AUDIOQS.events == nil then AUDIOQS.events = {} else wipe(AUDIOQS.events) end
		if AUDIOQS.segments == nil then AUDIOQS.segments = {} else wipe(AUDIOQS.segments) end
		
		-- Load Extensions
		for extName,_ in pairs(SV_Specializations[specId]) do 
			local thisExtFuncs = AUDIOQS.GetExtensionFuncs(extName)
			if thisExtFuncs["Initialize"] then
				thisExtFuncs["Initialize"]()
			end
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."  Loading EXT: "..extName) end
			AmmendTables(thisExtFuncs["GetSpells"](), thisExtFuncs["GetEvents"](), thisExtFuncs["GetSegments"]())
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
