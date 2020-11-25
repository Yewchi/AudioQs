-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local extName = "Covenants"
local extNameDetailed = "Covenants"
local extShortNames = "cov"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED -- TODO ExtensionsInterface needs update here

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
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
local extEvents = {
	["LOADING_SCREEN_ENABLED"] = {},
	["LOADING_SCREEN_DISABLED"] = {},
	["PLAYER_SPECIALIZATION_CHANGED"] = {}
}

local extSegments = {
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
	["PLAYER_SPECIALIZATION_CHANGED"] = {
		{
			{
				"AUDIOQS.ChargeCooldownsAllowed = false return false",
				false
			},
			{0.25, 	nil, nil, true},
			{nil,	nil, nil, "AUDIOQS.ChargeCooldownsAllowed = true return true"}
		}
	}
}

do -- check chosen covenant. TODO Is this primitive? Rushed the design and just stepping into solution
	--- Data for garbage collection --
	
	-- NOTE TO ANYONE READING CODE -- I hope this code burns in the hottest fire of hell. Everything's working fine but it's the least extensible most redundant crap I could imagine. Honestly.. I have some gearing up to do.
	local COVENANT_ABILITY_SPELL_NAME = 1
	local COVENANT_ABILITY_FILE_NAME = 2 -- TODO Dork over to this behaviour for covenants. Only repeats the question of why spell cd prompt data still isn't mostly auto-generated, with just overrides for special functionality.
	local COVENANT_ABILITY_SPELL_ID = 3

	local basicCovenantAbilityInfo = {
		[324739] = { "Summon Steward", 	"summon_steward"}, 
		[300728] = { "Door of Shadows",	"door_of_shadows"},
		[324631] = { "Fleshcraft",		"fleshcraft"},
		[310143] = { "Soulshape",		"soulshape"}
	}

	
	local basicCovenantAbilityToClassAbilityInfo = {
		[324739] = {
			[2] 	= { "Divine Toll",				"divine_toll", 				304971},
			[3] 	= {	"Resonating Arrow",			"resonating_arrow", 		308491},
			[5] 	= {	"Boon of the Ascended",		"boon_of_the_ascended", 	325013},
			[7] 	= {	"Vesper Totem",				"vesper_totem",				324386},
			[10] 	= {	"Weapons of Order",			"weapons_of_order",			310454},
			[11] 	= {	"Kindred Spirits",			"kindred_spirits",			326434},
		},
		[300728] = {
			[2] 	= {	"Ashen Hallow",				"ashen_hallow",				316958},
			[3] 	= {	"Flayed Show",				"flayed_shot",				324149},
			[5] 	= { "Mindgames",				"mindgames",				323673},
			[7] 	= {	"Chain Harvest",			"chain_harvest",			320674},
			[10] 	= {	"Fallen Order",				"fallen_order",				326860},
			[11] 	= {	"Ravenous Frenzy",			"ravenous_frenzy",			323546},
		},
		[331180] = {
			[2] 	= {	"Vanquisher's Hammer",		"vanquishers_hammer",		328204},
			[3] 	= {	"Death Chakram",			"death_chakram",			325028},
			[5] 	= {	"Unholy Nova",				"unholy_nova",				324724},
			[7] 	= {	"Primordial Wave",			"primordial_wave",			326059},
			[10] 	= {	"Bonedust Brew",			"bonebust_brew",			325216},
			[11] 	= {	"Adaptive Swarm",			"adaptive_swarm",			325727},
		},
		[310143] = {
			[2] 	= {	"Blessing of the Seasons",	"blessing_of_the_seasons",	328278},
			[3] 	= {	"Wild Spirits",				"wild_spirits",				328231},
			[5] 	= {	"Fae Guardians",			"fae_guardians",			327661},
			[7] 	= {	"Fae Transfusion",			"fae_transfusion",			328923},
			[10] 	= {	"Faeline Stomp",			"faeline_stomp",			327104},
			[11] 	= {	"Convoke the Spirits",		"convoke_the_spirits",		323764},
		}
	}
	
	local classToClassCovenantAbilitiesInfo = {
		[2] = { 
			{ 	"Divine Toll",				"divine_toll", 				304971},
			{	"Ashen Hallow",				"ashen_hallow",				316958},
			{	"Vanquisher's Hammer",		"vanquishers_hammer",		328204},
			{	"Blessing of the Seasons",	"blessing_of_the_seasons",	328278} 
		},
		[3] = {
			{	"Resonating Arrow",			"resonating_arrow", 		308491},
			{	"Death Chakram",			"death_chakram",			325028},
			{	"Death Chakram",			"death_chakram",			325028},
			{	"Wild Spirits",				"wild_spirits",				328231}
		},
		[5] = {
			{	"Boon of the Ascended",		"boon_of_the_ascended", 	325013},
			{ 	"Mindgames",				"mindgames",				323673},
			{	"Unholy Nova",				"unholy_nova",				324724},
			{	"Fae Guardians",			"fae_guardians",			327661}
		},
		[7] = {
			{	"Vesper Totem",				"vesper_totem",				324386},
			{	"Chain Harvest",			"chain_harvest",			320674},
			{	"Primordial Wave",			"primordial_wave",			326059},
			{	"Fae Transfusion",			"fae_transfusion",			328923}
		},
		[10] = {
			{	"Weapons of Order",			"weapons_of_order",			310454},
			{	"Fallen Order",				"fallen_order",				326860},
			{	"Bonedust Brew",			"bonebust_brew",			325216},
			{	"Faeline Stomp",			"faeline_stomp",			327104}
		},
		[11] = {
			{	"Kindred Spirits",			"kindred_spirits",			326434},
			{	"Ravenous Frenzy",			"ravenous_frenzy",			323546},
			{	"Adaptive Swarm",			"adaptive_swarm",			325727},
			{	"Convoke the Spirits",		"convoke_the_spirits",		323764}
		},
	}
	-- /Data for garbage collection --
	
	local basicCovenantSpellId = ( 
			(IsSpellKnown(324739) and 324739) or 
			(IsSpellKnown(300728) and 300728) or 
			(IsSpellKnown(324631) and 324631) or 
			(IsSpellKnown(310143) and 310143) )
	if ( basicCovenantSpellId ) then
		local knownBasicCovenantAbilityInfo = basicCovenantAbilityInfo[basicCovenantSpellId]
		local covenantClassAbilityInfo = basicCovenantAbilityToClassAbilityInfo[basicCovenantSpellId][AUDIOQS.GetClassId()]
		local thisCovenantClassSpellId = covenantClassAbilityInfo[COVENANT_ABILITY_SPELL_ID]
		extSpells[ basicCovenantSpellId ] = 
				{knownBasicCovenantAbilityInfo[COVENANT_ABILITY_SPELL_NAME], 0, 0, 0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}  -- TODO ugly results of avoiding implementing prompt generation
		extSpells[ thisCovenantClassSpellId ] =
				{covenantClassAbilityInfo[COVENANT_ABILITY_SPELL_NAME], 0, 0, 0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}
		extSegments[ basicCovenantSpellId ] = 
				{
					{
						{
							"return AUDIOQS.spells["..basicCovenantSpellId.."][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot["..basicCovenantSpellId.."][AUDIOQS.SPELL_EXPIRATION] > 0",
							false
						},
						{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Covenants/"..knownBasicCovenantAbilityInfo[COVENANT_ABILITY_FILE_NAME]..".ogg",		nil,	true }
					}
				}
		extSegments[ thisCovenantClassSpellId ] =
				{
					{
						{
							"return AUDIOQS.spells["..thisCovenantClassSpellId.."][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot["..thisCovenantClassSpellId.."][AUDIOQS.SPELL_EXPIRATION] > 0",
							false
						},
						{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Covenants/"..covenantClassAbilityInfo[COVENANT_ABILITY_FILE_NAME]..".ogg",		nil,	true }
					}
				}
	else -- just do a manual search for each class. Not a permanent sol^n. Doesn't work when switching abilities.
		local myClassCovenantAbilitiesInfo = classToClassCovenantAbilitiesInfo[AUDIOQS.GetClassId()]
		for i,abilityInfo in pairs(myClassCovenantAbilitiesInfo) do
			local thisSpellId = abilityInfo[COVENANT_ABILITY_SPELL_ID]
			if IsSpellKnown(thisSpellId) then
				extSpells[ thisSpellId ] =
				{abilityInfo[COVENANT_ABILITY_SPELL_NAME], 0, 0, 0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}
				extSegments[ thisSpellId ] =
				{
					{
						{
							"return AUDIOQS.spells["..thisSpellId.."][AUDIOQS.SPELL_EXPIRATION] == 0 and AUDIOQS.spellsSnapshot["..thisSpellId.."][AUDIOQS.SPELL_EXPIRATION] > 0",
							false
						},
						{nil,		AUDIOQS.SOUND_PATH_PREFIX..AUDIOQS.SOUNDS_ROOT.."Cooldowns/Covenants/"..abilityInfo[COVENANT_ABILITY_FILE_NAME]..".ogg",		nil,	true }
					}
				}
				break
			end
		end
	end
end
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