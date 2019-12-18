--#ifdef WOW_CLASSIC
if AQ.WOW_CLASSIC then
-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "ClassicPriest"
local extNameDetailed = "ClassicPriest"
local extShortNames = "clcpriest"
local extSpecLimit = 5 -- TODO ExtensionsInterface needs update here

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
	[2944] = { 	"Devouring Plague", 0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[586] = { 	"Fade", 			0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[8122] = { 	"Psychic Scream", 	0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[724] = { 	"Lightwell", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[13908] = { "Desperate Prayer", 0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[13896] = { "Feedback", 		0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY},
	[2651] = { 	"Elune's Grace", 	0, 	0, 	0, 	"player", 	AQ.SPELL_TYPE_ABILITY}
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {},
}

local extSegments = {
	[2944] = {
		{
			{
				"return AQ.spells[2944][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[2944][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/devouring_plague.ogg",		nil,	true }
		}
	},
	[586] = {
		{
			{
				"return AQ.spells[586][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[586][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/fade.ogg",		nil,	true }
		}
	},
	[8122] = {
		{
			{
				"return AQ.spells[8122][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[8122][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/psychic_scream.ogg",		nil,	true }
		}
	},
	[724] = {
		{
			{
				"return AQ.spells[724][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[724][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/lightwell.ogg",		nil,	true }
		}
	},
	[13908] = {
		{
			{
				"return AQ.spells[13908][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[13908][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/desperate_prayer.ogg",		nil,	true }
		}
	},
	[13896] = {
		{
			{
				"return AQ.spells[13896][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[13896][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/feedback.ogg",		nil,	true }
		}
	},
	[2651] = {
		{
			{
				"return AQ.spells[2651][AQ.SPELL_EXPIRATION] == 0 and AQ.spellsSnapshot[2651][AQ.SPELL_EXPIRATION] > 0",
				false
			},
			{nil,		AQ.SOUND_PATH_PREFIX..AQ.SOUNDS_ROOT.."Cooldowns/elunes_grace.ogg",		nil,	true }
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