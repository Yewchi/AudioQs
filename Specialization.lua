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
AQ.COMBAT_LOG_SOURCE_GUID = 4
AQ.COMBAT_LOG_SPELL_ID = 12
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
function AQ.SpecHasPrompts(specIdToCheck)
	return AQ.GSI_SpecHasPrompts(specIdToCheck)
end

function AQ.SetAbilityAndAuraTables(newAbilities, newAuras)
	abilityTable = newAbilities
	auraTable = newAuras
end

-------- AQ.FindPromptsFromUnitAura()
function AQ.FindPromptsFromUnitAura(aura)
	if aura[AQ.UNIT_AURA_TIME_MOD] ~= AURA_ALWAYS_IS_VALUE then
		error({code=AQ.ERR_INVALID_AURA_DATA, func=string.format("FindPromptsFromUnitAura(aura=%s)", aura[AQ.UNIT_AURA_NAME])})
	end
	
	if AQ.GSI_AuraIsIncluded(aura[AQ.UNIT_AURA_SPELL_ID]) then 
		return AQ.ProcessAuraForPrompts(aura)
	end
end

-------- AQ.ProcessCustomEventForPrompts()
function AQ.ProcessCustomEventForPrompts(event, ...)
	if AQ.GSI_EventIsIncluded(event) then
		AQ.GSI_UpdateEventTable(event, ...)
		AQ.AttemptStartPrompt(event)
	end
end

-------- AQ.ProcessCombatLogForPrompts()
function AQ.ProcessCombatLogForPrompts()
	local combatLogEventInfo = AQ.LoadCombatLog()
	local spellId = combatLogEventInfo[AQ.COMBAT_LOG_SPELL_ID]
	local spell = AQ.GSI_GetSpell(spellId)
	
	if spell == nil or combatLogEventInfo[AQ.COMBAT_LOG_SOURCE_GUID] ~= AQ.PLAYER_GUID then
		return
	end
	
	if spell[AQ.SPELL_SPELL_TYPE] == AQ.SPELL_TYPE_ABILITY then
		local cdStart, cdDur = GetSpellCooldown(spellId)
		local cdExpiration = cdStart + cdDur
		
		if AQ.IsEqualToGcd(cdDur) then  
			if AQ.GSI_UpdateSpellTable(spellId, cdDur, cdExpiration) then
				AQ.AttemptStartPrompt(spellId)
			else
				AQ.CheckPrompts()
			end
		end
	end
end

function AQ.ProcessSpell(spellId, currTime) -- TODO Poorly named
	local cdStart, cdDur = GetSpellCooldown(spellId)
	local charges = GetSpellCharges(spellId)
	local foundChange = false
	
	if(charges ~= nil and charges ~= AQ.spells[spellId][AQ.SPELL_CHARGES]) then -- TODO Hacky
		if AQ.GSI_UpdateSpellTable(spellId, cdDur, cdStart+cdDur) then 
			AQ.AttemptStartPrompt(spellId)
			return true
		end
	end
	
	local cdExpiration = AQ.spells[spellId][AQ.SPELL_EXPIRATION]
	local calculatedCdExpiration = cdStart + cdDur
	if cdExpiration > 0 then
		if currTime > cdExpiration-0.15 then -- Completely avoids GCD in spell's cooldown data issue.
			cdStart = 0
			cdDur = 0
			calculatedCdExpiration = cdStart + cdDur
		end
	
		if cdDur == 0 then
			if AQ.GSI_UpdateSpellTable(spellId, cdDur, calculatedCdExpiration) then
				foundChange = true
				AQ.AttemptStartPrompt(spellId)
			end
		end
	elseif currTime < calculatedCdExpiration-0.15 and select(2, GetSpellLossOfControlCooldown(spellId)) ~= cdDur then -- TODO LoC cooldown check should be highly-placed.
		if AQ.GSI_UpdateSpellTable(spellId, cdDur, calculatedCdExpiration) then
			foundChange = true
			AQ.AttemptStartPrompt(spellId)
		end
	end
	
	return foundChange
end

-------- AQ.ProcessSpellCooldownForPrompts()
function AQ.ProcessSpellCooldownsForPrompts()
	local currTime = GetTime()
	local foundChange = false
	
	for n=1,#abilityTable,1 do
		local spellId = abilityTable[n]
		local charges = GetSpellCharges(spellId)
		local cdDur = GetSpellCooldown(spellId)
		if cdDur > 1.5 or (cdDur == 0 and AQ.spells[spellId][AQ.SPELL_EXPIRATION] > 0) or (charges ~= nil and charges ~= AQ.spells[spellId][AQ.SPELL_CHARGES]) then
			if AQ.ProcessSpell(spellId, currTime) and not foundChange then
				foundChange = true
			end
		end
	end
	
	if not foundChange then -- TODO Needed?
		AQ.CheckPrompts()
	end
end

-- Puting full aura table processing in here, then call this func, such that
--   we don't require passing table spell refs to core.
-------- AQ.ProccessAuraForPrompts()
function AQ.ProcessAuraForPrompts(aura)
	if aura == nil then
		error({code=AQ.ERR_INVALID_ARGS, func="ProcessAuraForPrompts(aura=nil)"})
	end

	local cdDur, cdExpiration, spellId = aura[AQ.UNIT_AURA_DURATION], aura[AQ.UNIT_AURA_EXPIRATION], aura[AQ.UNIT_AURA_SPELL_ID]
	local spellIncluded = AQ.GSI_SpellIsIncluded(spellId)

	if spellIncluded == nil then
		error({code=AQ.ERR_UNKNOWN_SPELL_AS_ARGUMENT, func="ProcessAuraForPrompts(aura="..(AQ.PrintableTable(aura))..")"})
	elseif AQ.GSI_UpdateSpellTable(spellId, cdDur, cdExpiration) then
		AQ.AttemptStartPrompt(spellId)
	end

end

-------- AQ.LoadSpecialization()
function AQ.LoadSpecialization()
	local specId = AQ.GetSpec()
if AQ.DEBUG then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."Attempting LoadSpecTables("..specId..").") end
	if AQ.GSI_LoadSpecTables(specId) then
if AQ.DEBUG then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."  Loaded specialization tables.") end
		abilityTable, auraTable = AQ.InitializePrompts()
		AQ.GSI_UpdateAllSpellTables(true)
if AQ.DEBUG then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."Prompt tables generated. Spell info updated.") end
	end
end
--
-- /Funcs --
