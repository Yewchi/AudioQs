-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local AUDIOQS = AUDIOQS_4Q5

local extName = "Covenants"
local extNameDetailed = "Covenants"
local extShortNames = "cov"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED -- TODO ExtensionsInterface needs update here
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
		["Initialize"] = function() AUDIOQS.COVENANT_ReloadCovenantAbilities() end
}
--- Spell Tables and Prompts --
--
-- spells[spellId] = { "Spell Name", charges, cdDur, cdExpiration, unitId, spellType}
extSpells = { 
}

-- events["EVENT_NAME"] = eventArgsArray (automatically generated)
extEvents = {
	["COVENANT_CHOSEN"] = {},
}

extSegments = {
	["COVENANT_CHOSEN"] = {
		{
			{
				function() AUDIOQS.COVENANT_ReloadCovenantAbilities() return false end,
				false
			},
			{}
		}
	}
}

function AUDIOQS.COVENANT_ReloadCovenantAbilities()
	--- Data for garbage collection --
	local COVENANT_ABILITY_SPELL_NAME = 1
	local COVENANT_ABILITY_FILE_NAME = 2
	local COVENANT_ABILITY_SPELL_ID = 3

	local basicCovenantAbilityInfo = {
		{ "Summon Steward", 	"summon_steward", 	324739}, -- 1 	Kyrian
		{ "Door of Shadows",	"door_of_shadows", 	300728}, -- 2	Venthyr
		{ "Soulshape",			"soulshape", 		310143}, -- 3	Night Fae
		{ "Fleshcraft",			"fleshcraft",		324631}  --	4	Necrolord
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
		[310143] = {
			[2] 	= {	"Blessing of the Seasons",	"blessing_of_the_seasons",	328278},
			[3] 	= {	"Wild Spirits",				"wild_spirits",				328231},
			[5] 	= {	"Fae Guardians",			"fae_guardians",			327661},
			[7] 	= {	"Fae Transfusion",			"fae_transfusion",			328923},
			[10] 	= {	"Faeline Stomp",			"faeline_stomp",			327104},
			[11] 	= {	"Convoke the Spirits",		"convoke_the_spirits",		323764},
		},
		[324631] = {
			[2] 	= {	"Vanquisher's Hammer",		"vanquishers_hammer",		328204},
			[3] 	= {	"Death Chakram",			"death_chakram",			325028},
			[5] 	= {	"Unholy Nova",				"unholy_nova",				324724},
			[7] 	= {	"Primordial Wave",			"primordial_wave",			326059},
			[10] 	= {	"Bonedust Brew",			"bonebust_brew",			325216},
			[11] 	= {	"Adaptive Swarm",			"adaptive_swarm",			325727},
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
	local covenantChosen = C_Covenants.GetActiveCovenantID()
	if ( covenantChosen and covenantChosen ~= 0 ) then
		local knownBasicCovenantAbilityInfo = basicCovenantAbilityInfo[covenantChosen]
		local basicCovenantSpellId = knownBasicCovenantAbilityInfo[COVENANT_ABILITY_SPELL_ID]
		local covenantClassAbilityInfo = basicCovenantAbilityToClassAbilityInfo[basicCovenantSpellId][AUDIOQS.GetClassId()]
		local thisCovenantClassSpellId = covenantClassAbilityInfo[COVENANT_ABILITY_SPELL_ID]
		extSpells[ basicCovenantSpellId ] = 
				{knownBasicCovenantAbilityInfo[COVENANT_ABILITY_SPELL_NAME], 0, 0, 0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}  -- TODO ugly results of avoiding implementing prompt generation
		extSpells[ thisCovenantClassSpellId ] =
				{covenantClassAbilityInfo[COVENANT_ABILITY_SPELL_NAME], 0, 0, 0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}
		extSegments[ basicCovenantSpellId ] = 
				{
					AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Covenants/"..knownBasicCovenantAbilityInfo[COVENANT_ABILITY_FILE_NAME]..".ogg")
				}
		extSegments[ thisCovenantClassSpellId ] =
				{
					AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Covenants/"..covenantClassAbilityInfo[COVENANT_ABILITY_FILE_NAME]..".ogg")
				}
	else -- just do a manual search for each class. Not a permanent sol^n. Doesn't work when switching abilities.
		local myClassCovenantAbilitiesInfo = classToClassCovenantAbilitiesInfo[AUDIOQS.GetClassId()]
		for _,abilityInfo in pairs(myClassCovenantAbilitiesInfo) do
			local thisSpellId = abilityInfo[COVENANT_ABILITY_SPELL_ID]
			if IsSpellKnown(thisSpellId) then
				extSpells[ thisSpellId ] =
				{abilityInfo[COVENANT_ABILITY_SPELL_NAME], 0, 0, 0, 	"player", 	AUDIOQS.SPELL_TYPE_ABILITY}
				extSegments[ thisSpellId ] =
				{
					AUDIOQS.SEGLIB_CREATE_GENERIC_SPELL_COOLDOWN_SEGMENT("Cooldowns/Covenants/"..abilityInfo[COVENANT_ABILITY_FILE_NAME]..".ogg")
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
--
-- /Funcs --

-- Register Extension:
ext_ref_num = AUDIOQS.RegisterExtension(extName, extFuncs)