-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local AUDIOQS = AUDIOQS_4Q5
--#ifdef WOW_CLASSIC
if AUDIOQS.WOW_CLASSIC then

local extName = "ClassicShaman"
local extNameDetailed = "ClassicShaman"
local extShortNames = "clcshaman"
local extSpecLimit = 7 -- TODO ExtensionsInterface needs update here
local ext_ref_num

local extSpells, extEvents, extSegments

local extFuncs = { -- For external use
		["GetName"] = function() return extName end,
		["GetNameDetailed"] = function() return extNameDetailed end,
		["GetShortNames"] = function() return extShortNames end,
		["GetExtRef"] = function() return ext_ref_num end,
		["GetVersion"] = function() return extVersion end,
		["GetSpells"] = function() return extSpells end,
		["GetEvents"] = function() return extEvents end,
		["GetPrompts"] = function() return extSegments end,
		["GetExtension"] = function() 
				return {
					spells=extSpells,
					events=extEvents,
					segments=extSegments,
					extNum=ext_ref_num
				} 
			end,
		["SpecAllowed"] = function(specId) 
				if extSpecLimit == AUDIOQS.ANY_SPEC_ALLOWED or extSpecLimit == specId then
					return true
				end 
			end,
		["Initialize"] = function() end
}

--- Spell Tables and Prompts --
--
-- spells[spellId] = { "Spell Name", charges, cdDur, cdExpiration, unitId, spellType}
extSpells = {	
	[556] = { 	"Astral Recall", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[2825] = { 	"Bloodlust", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[2026] = { 	"Earth Elemental Totem",0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[2484] = {	"Earthbind Totem", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[16166] = {	"Elemental Mastery", 	0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[2894] = { 	"Fire Elemental Totem", 0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[1535] = {	"Fire Nova Totem", 		0,	0,	0,	"player",	AUDIOQS.SPELL_TYPE_ABILITY},
	[32182] = { "Heroism", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[5730] = {	"Stoneclaw Totem", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
extEvents = {
}

extSegments = {
	[556] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/astral_recall.ogg")
	},
	[2825] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/bloodlust.ogg")
	},
	[2026] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/earth_elemental.ogg")
	},
	[2484] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/earthbind_totem.ogg")
	},
	[16166] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/elemental_mastery.ogg")
	},
	[2894] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/fire_elemental.ogg")
	},
	[1535] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/fire_nova_totem.ogg")
	},
	[32182] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/heroism.ogg")
	},
	[5730] = {
		AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Shaman/stoneclaw_totem.ogg")
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

GetVersion = function()
	return extVersion
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
ext_ref_num = AUDIOQS.RegisterExtension(extName, extFuncs)
end
--#endif
