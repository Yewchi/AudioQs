-- All code written and maintained by Yewchi
-- zyewchi@gmail.com

--~ Top-level processing of events in relation to prompts and the GameStateInterface; Interfaces the loading of specialization data.

-- Needs further abstraction.

-- TODO Cooldown tracking is 1-part safe, extendible code, 2-parts garbage-can-fire and redundant checks.

local AURA_ALWAYS_IS_VALUE = 1 -- using value #15: timeMod

--- Initialization --
--
------- Table key reference --
--
AUDIOQS.COMBAT_LOG_SOURCE_GUID = 4
AUDIOQS.COMBAT_LOG_SPELL_ID = 12
--
------ /Table key reference --

------- AddOn variables --
--
local abilityTable = {}
local auraTable = {}
--
------ /AddOn variables --
--
-- /Initialization --

--- Funcs --
--
function AUDIOQS.SpecHasPrompts(specIdToCheck)
	return AUDIOQS.GSI_SpecHasPrompts(specIdToCheck)
end

function AUDIOQS.SetAbilityAndAuraTables(newAbilities, newAuras)
	abilityTable = newAbilities
	auraTable = newAuras
end

-------- AUDIOQS.FindPromptsFromUnitAura()
function AUDIOQS.FindPromptsFromUnitAura(aura)
	if aura[AUDIOQS.UNIT_AURA_TIME_MOD] ~= AURA_ALWAYS_IS_VALUE then
		error({code=AUDIOQS.ERR_INVALID_AURA_DATA, func=string.format("FindPromptsFromUnitAura(aura=%s)", aura[AUDIOQS.UNIT_AURA_NAME])})
	end
	
	if AUDIOQS.GSI_AuraIsIncluded(aura[AUDIOQS.UNIT_AURA_SPELL_ID]) then 
		return AUDIOQS.ProcessAuraForPrompts(aura)
	end
end

-------- AUDIOQS.ProcessCustomEventForPrompts()
function AUDIOQS.ProcessCustomEventForPrompts(event, ...)
	if AUDIOQS.GSI_EventIsIncluded(event) then
		AUDIOQS.GSI_UpdateEventTable(event, ...)
		AUDIOQS.AttemptStartPrompt(event)
	end
end

-------- AUDIOQS.ProcessCombatLogForPrompts()
function AUDIOQS.ProcessCombatLogForPrompts()
	local combatLogEventInfo = AUDIOQS.LoadCombatLog()
	local spellId = combatLogEventInfo[AUDIOQS.COMBAT_LOG_SPELL_ID]
	local spell = AUDIOQS.GSI_GetSpell(spellId)
	
	if spell == nil or combatLogEventInfo[AUDIOQS.COMBAT_LOG_SOURCE_GUID] ~= AUDIOQS.PLAYER_GUID then
		return
	end
	
	if spell[AUDIOQS.SPELL_SPELL_TYPE] == AUDIOQS.SPELL_TYPE_ABILITY then
		local cdStart, cdDur = GetSpellCooldown(spellId)
		local cdExpiration = cdStart + cdDur
		
		if AUDIOQS.IsEqualToGcd(cdDur) then  
			if AUDIOQS.GSI_UpdateSpellTable(spellId, cdDur, cdExpiration) then
				AUDIOQS.AttemptStartPrompt(spellId)
			else
				AUDIOQS.CheckPrompts()
			end
		end
	end
end

function AUDIOQS.ProcessSpell(spellId, currTime) -- TODO Poorly named
	local cdStart, cdDur = GetSpellCooldown(spellId)
	local charges = GetSpellCharges(spellId)
	local foundChange = false
	
	if(charges ~= nil and charges ~= AUDIOQS.spells[spellId][AUDIOQS.SPELL_CHARGES]) then -- TODO Hacky
		if AUDIOQS.GSI_UpdateSpellTable(spellId, cdDur, cdStart+cdDur) then 
			AUDIOQS.AttemptStartPrompt(spellId)
			return true
		end
	end
	
	local cdExpiration = AUDIOQS.spells[spellId][AUDIOQS.SPELL_EXPIRATION]
	local calculatedCdExpiration = cdStart + cdDur
	if cdExpiration > 0 then
		if currTime > cdExpiration-0.15 then -- Completely avoids GCD in spell's cooldown data issue.
			cdStart = 0
			cdDur = 0
			calculatedCdExpiration = cdStart + cdDur
		end
	
		if cdDur == 0 then
			if AUDIOQS.GSI_UpdateSpellTable(spellId, cdDur, calculatedCdExpiration) then
				foundChange = true
				AUDIOQS.AttemptStartPrompt(spellId)
			end
		end
	elseif currTime < calculatedCdExpiration-0.15 and select(2, GetSpellLossOfControlCooldown(spellId)) ~= cdDur then -- TODO LoC cooldown check should be highly-placed.
		if AUDIOQS.GSI_UpdateSpellTable(spellId, cdDur, calculatedCdExpiration) then
			foundChange = true
			AUDIOQS.AttemptStartPrompt(spellId)
		end
	end
	
	return foundChange
end

-------- AUDIOQS.ProcessSpellCooldownForPrompts()
function AUDIOQS.ProcessSpellCooldownsForPrompts()
	local currTime = GetTime()
	local foundChange = false
	
	for n=1,#abilityTable,1 do
		local spellId = abilityTable[n]
		local charges = GetSpellCharges(spellId)
		local cdDur = GetSpellCooldown(spellId)
		if cdDur > 1.5 or (cdDur == 0 and AUDIOQS.spells[spellId][AUDIOQS.SPELL_EXPIRATION] > 0) or (charges ~= nil and charges ~= AUDIOQS.spells[spellId][AUDIOQS.SPELL_CHARGES]) then
			if AUDIOQS.ProcessSpell(spellId, currTime) and not foundChange then
				foundChange = true
			end
		end
	end
	
	if not foundChange then -- TODO Needed?
		AUDIOQS.CheckPrompts()
	end
end

-- Puting full aura table processing in here, then call this func, such that
--   we don't require passing table spell refs to core.
-------- AUDIOQS.ProccessAuraForPrompts()
function AUDIOQS.ProcessAuraForPrompts(aura)
	if aura == nil then
		error({code=AUDIOQS.ERR_INVALID_ARGS, func="ProcessAuraForPrompts(aura=nil)"})
	end

	local cdDur, cdExpiration, spellId = aura[AUDIOQS.UNIT_AURA_DURATION], aura[AUDIOQS.UNIT_AURA_EXPIRATION], aura[AUDIOQS.UNIT_AURA_SPELL_ID]
	local spellIncluded = AUDIOQS.GSI_SpellIsIncluded(spellId)

	if spellIncluded == nil then
		error({code=AUDIOQS.ERR_UNKNOWN_SPELL_AS_ARGUMENT, func="ProcessAuraForPrompts(aura="..(AUDIOQS.PrintableTable(aura))..")"})
	elseif AUDIOQS.GSI_UpdateSpellTable(spellId, cdDur, cdExpiration) then
		AUDIOQS.AttemptStartPrompt(spellId)
	end

end

-------- AUDIOQS.LoadSpecialization()
function AUDIOQS.LoadSpecialization()
	local specId = AUDIOQS.GetSpec()
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Attempting LoadSpecTables("..specId..").") end
	if AUDIOQS.GSI_LoadSpecTables(specId) then
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."  Loaded specialization tables.") end
		abilityTable, auraTable = AUDIOQS.InitializePrompts()
		AUDIOQS.GSI_UpdateAllSpellTables(true)
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Prompt tables generated. Spell info updated.") end
	end
end
--
-- /Funcs --
