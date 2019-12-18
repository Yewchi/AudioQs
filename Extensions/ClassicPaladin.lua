--#ifdef WOW_CLASSIC
if AQ.WOW_CLASSIC then
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
	[642] = { 	"Divine Shield", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[853] = { 	"Hammer of Justice", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[20473] = { "Holy Shock", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[1022] = { 	"Blessing of Protection", 	0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[633] = { 	"Lay on Hands", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	--[20925] = { "Holy Shield", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[498] = { 	"Divine Protection", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[2812] = { 	"Holy Wrath", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[2878] = { 	"Turn Undead", 				0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY}
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
				"return AQ.spells[642][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[642][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/divine_shield.ogg",		nil,	true }
		}
	},
	[853] = {
		{
			{
				"return AQ.spells[853][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[853][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/hammer_of_justice.ogg",		nil,	true }
		}
	},
	[20473] = {
		{
			{
				"return AQ.spells[20473][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[20473][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/holy_shock.ogg",		nil,	true }
		}
	},
	[1022] = {
		{
			{
				"return AQ.spells[1022][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[1022][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/blessing_of_protection.ogg",		nil,	true }
		}
	},
	[633] = {
		{
			{
				"return AQ.spells[633][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[633][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/lay_on_hands.ogg",		nil,	true }
		}
	},
	--[[[20925] = {
		{
			{
				"return AQ.spells[20925][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[20925][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/holy_shield.ogg",		nil,	true }
		}
	},--]]
	[498] = {
		{
			{
				"return AQ.spells[498][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[498][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/divine_protection.ogg",		nil,	true }
		}
	},
	[2812] = {
		{
			{
				"return AQ.spells[2812][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[2812][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/holy_wrath.ogg",		nil,	true }
		}
	},
	[2878] = {
		{
			{
				"return AQ.spells[2878][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[2878][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/turn_undead.ogg",		nil,	true }
		}
	},
	["LOADING_SCREEN_DISABLED"] = { -- TODO Should be in an "essentials", hidden extension or in the AudioQs.lua main event handlers. Workaround for now.
		{
			{
				"AQ.ChargeCooldownsAllowed = false return true",
				false
			},
			{0.25, 	nil, nil, true},
			{nil,	nil, nil, "AQ.ChargeCooldownsAllowed = true return true"}
		}
	},
	["LOADING_SCREEN_ENABLED"] = { -- TODO Likewise ^^
		{
			{
				"AQ.ChargeCooldownsAllowed = false return false",
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
	if extSpecLimit == AQ.ANY_SPEC_ALLOWED or extSpecLimit == specId then
		return true
	end
	return false
end
--
-- /Funcs --

-- Register Extension:
AQ.RegisterExtension(extName, extFuncs)
end
--#endif