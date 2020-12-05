-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

--~ This serves as both a regular Beast Mastery extension, as well as the main example of an implemented extension.
--~ This file is intended for WoW programmers, and would be overwelming for most others. Please email me if you need specific prompts made, or help writing segment data: zyewchi@gmail.com 

local extName = "BeastMastery"
local extNameDetailed = "Beast Mastery"
local extShortNames = "bm"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED -- Beast Mastery specId

-- Note that if the string funcs in a prompt need a static flag or bitmask to check against, that data is not available
-- in the string func's local scope, which is, the global table, and itself (not this file). This is why a flag or static 
-- value must be declared in the global Lua space (AUDIOQS.GS.BM_FRENZY_APPLIED = 0xFF). This raises the question of design: 
-- the reason the prompting system has been designed in such a way is purely for extensibility. 

-- Functions predeclared
local GetName
local GetNameDetailed
local GetShortNames
local GetVersion
local GetSpells
local GetEvents
local GetSegments
local GetExtension
local SpecAllowed

local extFuncs = {
		["GetName"] = function() return GetName() end,
		["GetNameDetailed"] = function() return GetNameDetailed() end,
		["GetShortNames"] = function() return GetShortNames() end,
		["GetVersion"] = function() return GetVersion() end,
		["GetSpells"] = function() return GetSpells() end,
		["GetEvents"] = function() return GetEvents() end,
		["GetSegments"] = function() return GetSegments() end,
		["GetExtension"] = function() return GetExtension() end,
		["SpecAllowed"] = function(specId) return SpecAllowed(specId) end,
		["Initialize"] = function() end
}

-- Below lists the spells, events and segments tables.
-- The spells table lists every spell which will cause SPELL_UPDATE_COOLDOWN and SPELL_UPDATE_CHARGES events to begin a check to see if the spell's state has changed, further to a AttemptStartOnPrompt() call on success.
-- The events table lists each event which will be registered as custom to perform their segments checks. Stores the most recent passed args, and as such is initialized empty.
-- The segments table lists each of the spells and events above, for 

--- Spell Tables and Prompts --
--
-- spells[spellId] = { "Spell Name", charges, cdDur, cdExpiration, unitId, spellType}
local extSpells = { 
		[217200] = 	{ "Barbed Shot", 			2, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY}, -- TODO If two prompts use the same spellId, spellName, unitId and spellType, they should be tracked as one spell as a single entry in the GSI data. Requires checking for similarities before adding.
		[272790] = 	{ "Frenzy", 				0, 	0, 	0, 	"pet", 			AUDIOQS.SPELL_TYPE_AURA},
		[53209] = 	{ "Chimaera Shot", 			0, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY},
		[131894] = 	{ "A Murder Of Crows", 		0, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY},
		[19574] = 	{ "Bestial Wrath", 			0, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY},
		[193530] = 	{ "Aspect of the Wild", 	0, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY},
		[186265] = 	{ "Aspect of the Turtle", 	0, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY},
		[186257] = 	{ "Aspect of the Cheetah", 	0, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY},
		[109304] = 	{ "Exhilaration", 			0, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY},
		[1543] = 	{ "Flare", 					0, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY},
		[187698] = 	{ "Tar Trap", 				0, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY},
		[187650] = 	{ "Freezing Trap", 			0, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY},
		[147362] = 	{ "Counter Shot", 			0, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY},
		[19577] = 	{ "Intimidation", 			0, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY},
		[34477] = 	{ "Misdirection", 			0, 	0, 	0, 	"player", 		AUDIOQS.SPELL_TYPE_ABILITY}
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
}

local checkLen = "local frenzyDuration = select("..AUDIOQS.UNIT_AURA_DURATION..", AUDIOQS.GetAuraInfo('pet', 272790)) if frenzyDuration == nil then return 0.0 end return frenzyDuration - 5.0" -- Only declared to maintain table width -- These evaluations are to be simplified into an evaluation language, in a later version.
local extSegments = {
--[[ [spellId][i] = { {startConditionals, stopConditionals}, {seg1}, {seg2}, ..., {segN} } ]]--
	[272790] = { -- Frenzy
		{
			{
				"return AUDIOQS.spells[272790][AUDIOQS.SPELL_EXPIRATION] > 0",	-- Start conditional
				"return UnitIsDeadOrGhost('pet')"								-- Stop conditional
			},
		--- {LNGTH,		SOUND_FILE,																		SndHndl,	CONDITIONAL }
			{checkLen, 	nil,																			nil,		true}, -- pause until 5 seconds left on Frenzy buff.
			{5.0, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Timers/pulse_1.ogg", 			nil,		"local frenzyStacks = select(AUDIOQS.UNIT_AURA_COUNT, AUDIOQS.GetAuraInfo(\"pet\", 272790)) if frenzyStacks == nil then return false end return frenzyStacks == 1"},
			{nil, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Timers/pulse_1_dropped.ogg", 	nil,		AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION}, -- If not refreshed, play on completion of previous segment. (Buff has dropped)
			{5.0, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Timers/pulse_2.ogg", 			nil,		"local frenzyStacks = select(AUDIOQS.UNIT_AURA_COUNT, AUDIOQS.GetAuraInfo(\"pet\", 272790)) if frenzyStacks == nil then return false end return frenzyStacks == 2"},
			{nil, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Timers/pulse_2_dropped.ogg",	nil,		AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION},
			{5.0, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Timers/pulse_3.ogg", 			nil,		"local frenzyStacks = select(AUDIOQS.UNIT_AURA_COUNT, AUDIOQS.GetAuraInfo(\"pet\", 272790)) if frenzyStacks == nil then return false end return frenzyStacks == 3"},
			{nil, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Timers/pulse_3_dropped.ogg",	nil,		AUDIOQS.PROMPTSEG_CONDITIONAL_CONTINUATION} 
		}
	},
	[217200] = { -- Barbed Shot
		{
			{
				"return AUDIOQS.spells[217200][AUDIOQS.SPELL_CHARGES] > AUDIOQS.spellsSnapshot[217200][AUDIOQS.SPELL_CHARGES]",
				false
			},
			{0.25, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."barbed_primer.ogg",			nil,		true },
			{nil, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."barbed_charge_1.ogg", 			nil,		"return GetSpellCharges(217200) == 1"},
			{nil, 		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."barbed_charge_2.ogg",			nil,		"return GetSpellCharges(217200) == 2"}
		}
	},
	[53209] = {
		{
			{
				"return AUDIOQS.spells[53209][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[53209][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Hunter/chimaera_shot.ogg",		nil,	true }
		}
	},
	[131894] = {
		{
			{
				"return AUDIOQS.spells[131894][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[131894][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Hunter/a_murder_of_crows.ogg",		nil,	true }
		},
	},
	[19574] = {
		{
			{
				"return AUDIOQS.spells[19574][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[19574][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Hunter/bestial_wrath.ogg",		nil,	true }
		}
	},
	[193530] = {
		{
			{
				"return AUDIOQS.spells[193530][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[193530][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Hunter/aspect_of_the_wild.ogg",		nil,	true }
		}
	},
	[186265] = {
		{
			{
				"return AUDIOQS.spells[186265][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[186265][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Hunter/aspect_of_the_turtle.ogg",		nil,	true }
		}
	},
	[186257] = {
		{
			{
				"return AUDIOQS.spells[186257][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[186257][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Hunter/aspect_of_the_cheetah.ogg",		nil,	true }
		}
	},
	[109304] = {
		{
			{
				"return AUDIOQS.spells[109304][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[109304][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Hunter/exhileration.ogg",		nil,	true }
		}
	},
	[1543] = {
		{
			{
				"return AUDIOQS.spells[1543][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[1543][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Hunter/flare.ogg",		nil,	true }
		}
	},
	[187698] = {
		{
			{
				"return AUDIOQS.spells[187698][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[187698][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Hunter/tar_trap.ogg",		nil,	true }
		}
	},
	[187650] = {
		{
			{
				"return AUDIOQS.spells[187650][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[187650][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Hunter/freezing_trap.ogg",		nil,	true }
		}
	},
	[147362] = {
		{
			{
				"return AUDIOQS.spells[147362][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[147362][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Hunter/counter_shot.ogg",		nil,	true }
		}
	},
	[19577] = {
		{
			{
				"return AUDIOQS.spells[19577][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[19577][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Hunter/intimidation.ogg",		nil,	true }
		}
	},
	[34477] = {
		{
			{
				"return AUDIOQS.spells[34477][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[34477][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Hunter/misdirection.ogg",		nil,	true }
		}
	},
}
--
-- /Spell Tables and Rules

--- Funcs --
--
GetName = function()
	return extName
end

GetNameDetailed = function()
	return extNameDetailed
end

GetShortNames = function()
	return extShortNames
end

GetSpells = function()
	return extSpells
end

GetEvents = function()
	return extEvents
end

GetSegments = function()
	return extSegments
end

GetExtension = function()
	return {spells=extSpells, events=extEvents, segments=extSegments}
end

SpecAllowed = function(specId)
	if extSpecLimit == AUDIOQS.ANY_SPEC_ALLOWED or extSpecLimit == specId then
		return true
	end
	return false
end
--
-- /Funcs --

-- Register Extension:
AUDIOQS.RegisterExtension(extName, extFuncs)
