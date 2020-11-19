--#ifdef WOW_CLASSIC
if AUDIOQS.WOW_CLASSIC then
-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "ClassicPaladin"
local extNameDetailed = "ClassicPaladin"
local extShortNames = "clcpaladin"
local extSpecLimit = 2 -- TODO ExtensionsInterface needs update here

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

--- Spell Tables and Prompts --
--
-- spells[spellId] = { "Spell Name", charges, cdDur, cdExpiration, unitId, spellType}
local extSpells = {	
	[642] = { 	"Divine Shield", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[853] = { 	"Hammer of Justice", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[20473] = { "Holy Shock", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[1022] = { 	"Blessing of Protection", 	0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[633] = { 	"Lay on Hands", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	--[20925] = { "Holy Shield", 			0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[498] = { 	"Divine Protection", 		0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[2812] = { 	"Holy Wrath", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY},
	[2878] = { 	"Turn Undead", 				0, 	0, 	0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {},
}

local extSegments = {
	[642] = {
		{
			{
				"return AUDIOQS.spells[642][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[642][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/divine_shield.ogg",		nil,	true }
		}
	},
	[853] = {
		{
			{
				"return AUDIOQS.spells[853][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[853][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/hammer_of_justice.ogg",		nil,	true }
		}
	},
	[20473] = {
		{
			{
				"return AUDIOQS.spells[20473][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[20473][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/holy_shock.ogg",		nil,	true }
		}
	},
	[1022] = {
		{
			{
				"return AUDIOQS.spells[1022][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[1022][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/blessing_of_protection.ogg",		nil,	true }
		}
	},
	[633] = {
		{
			{
				"return AUDIOQS.spells[633][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[633][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/lay_on_hands.ogg",		nil,	true }
		}
	},
	--[[[20925] = {
		{
			{
				"return AUDIOQS.spells[20925][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[20925][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/holy_shield.ogg",		nil,	true }
		}
	},--]]
	[498] = {
		{
			{
				"return AUDIOQS.spells[498][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[498][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Paladin/divine_protection.ogg",		nil,	true }
		}
	},
	[2812] = {
		{
			{
				"return AUDIOQS.spells[2812][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[2812][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Paladin/holy_wrath.ogg",		nil,	true }
		}
	},
	[2878] = {
		{
			{
				"return AUDIOQS.spells[2878][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot[2878][AUDIOQS.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Paladin/turn_undead.ogg",		nil,	true }
		}
	},
	["LOADING_SCREEN_DISABLED"] = { -- TODO Should be in an "essentials", hidden extension or in the AudioQs.lua main event handlers. Workaround for now.
		{
			{
				"AUDIOQS.ChargeCooldownsAllowed = false return true",
				false
			},
			{0.25, 	nil, nil, true},
			{nil,	nil, nil, "AUDIOQS.ChargeCooldownsAllowed = true return true"}
		}
	},
	["LOADING_SCREEN_ENABLED"] = { -- TODO Likewise ^^
		{
			{
				"AUDIOQS.ChargeCooldownsAllowed = false return false",
				false
			},
			{}
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
AUDIOQS.RegisterExtension(extName, extFuncs)
end
--#endif