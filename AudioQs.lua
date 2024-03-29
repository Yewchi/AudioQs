-- All code written and maintained by Yewchi 
-- Thanks to Slyckety and many others for helping with test. Couldn't do this without the help!
-- zyewchi@gmail.com

-- Dev note: I gelled out a much better naming convention in many hours coding Dota scripts, AudioQs is not refactored, but is moving that way. Should be: local_file_var, LOCAL_CONSTANT, LIB_GLOBAL_CONSTANT, LIB/TYPE_I_CONSTANT_INDEX, codeBlockScopeVar, t_local_file_tbl, local_file_do_stuff(), LIB_GlobalDoStuff()

AUDIOQS_4Q5 = {}
local AUDIOQS = AUDIOQS_4Q5

AUDIOQS.DEBUG = false
AUDIOQS.VERBOSE = AUDIOQS.DEBUG and true

-- NB. VERSION OF CLASSIC IS SET FORWARDS TO PRE-CATA FOR OUT-OF-THE-GATE UI UPDATE WORKING.
-- IF YOU'RE ON AN UNOFFICIAL WRATH SERVER CHANGE 40000 to 30000 BELOW
AUDIOQS.BUILD_VERSION = select(4, GetBuildInfo())
AUDIOQS.WOW_CLASSIC = AUDIOQS.BUILD_VERSION < 40000 -- Can this be more broadly determined?
AUDIOQS.WOW_VC = AUDIOQS.BUILD_VERSION < 20000 -- Vanilla classic (unsure about WOW UI API versioning for vanilla)
AUDIOQS.WOW_BCC = AUDIOQS.BUILD_VERSION >= 20000 and AUDIOQS.BUILD_VERSION < 40000
AUDIOQS.WOW_SHADOWLANDS = AUDIOQS.BUILD_VERSION >= 90000 -- To be removed after expac rollover -- TODO CTRL+F WOW_SHADOWLANDS
AUDIOQS.WOW_SPECS_IMPLEMENTED = AUDIOQS.BUILD_VERSION >= 50400

AUDIOQS.COMPAT_UNIT_HEALTH_FREQ = (AUDIOQS.WOW_SHADOWLANDS and "UNIT_HEALTH" or "UNIT_HEALTH_FREQUENT")

--- Initialization --
--
------- Filenames --
--
AUDIOQS.AUDIOQS_ROOT = 		"Interface/AddOns/AudioQs/"
AUDIOQS.SOUNDS_ROOT = 		AUDIOQS.AUDIOQS_ROOT.."Sounds/"
--
------ /Filenames --

------- Flags --
--
AUDIOQS.SPELL_TYPE_ABILITY = 								0xFFF0 -- Type of a spell which is to be checked
AUDIOQS.SPELL_TYPE_AURA = 									0xFFF1

AUDIOQS.SPEC_NOT_IMPLEMENTED =								0xFFFF -- Nothing exists in AudioQs.lua WTF file

AUDIOQS.ANY_SPEC_ALLOWED =									0xFFF0 -- For loading Extensions
AUDIOQS.ONE_SPEC_ALLOWED = 									0xFFF1
--
------ /Flags --

------- Table key references --
--
AUDIOQS.SPELL_SPELL_NAME = 1
AUDIOQS.SPELL_CHARGES = 2
AUDIOQS.SPELL_DURATION = 3
AUDIOQS.SPELL_EXPIRATION = 4
AUDIOQS.SPELL_UNIT_ID = 5
AUDIOQS.SPELL_SPELL_TYPE = 6
AUDIOQS.SPELL_TYPE_SPELL_ID = 7

AUDIOQS.UNIT_AURA_NAME = 1
AUDIOQS.UNIT_AURA_COUNT = 3
AUDIOQS.UNIT_AURA_DEBUFF_TYPE = 4
AUDIOQS.UNIT_AURA_DURATION = 5
AUDIOQS.UNIT_AURA_EXPIRATION = 6
AUDIOQS.UNIT_AURA_UNIT_ID = 7
AUDIOQS.UNIT_AURA_TIME_MOD = 15 -- always = 1. For prelim confirmation of a valid aura

AUDIOQS.SPEC_INFO_NUM = 1
AUDIOQS.SPEC_INFO_NAME = 2
AUDIOQS.UNIT_CLASS_NUM = 3

AUDIOQS.CLC_PLAYERLOCATION_NAME = 1
AUDIOQS.CLC_PLAYERLOCATION_CLASS_ID = 3
--
------ /Table key references --

------- Static vals --
--
AUDIOQS.PLAYER_GUID = UnitGUID("player")
AUDIOQS.SPELLID_GCD = 61304
AUDIOQS.HUSHMODE_OFF = 									0x0
AUDIOQS.HUSHMODE_USER = 									0xFFF0
AUDIOQS.HUSHMODE_LOADINGSCREEN = 						0xFFF1
--
------- /Static vals --

------- Return values --
--
AUDIOQS.SPELLS_SPELL_NOT_LISTED = 							0xFFF0
--
------ /Return values --

------- AddOn variables --
--
local customEventFrameTimestamp = 0
local customEventsRegisteredThisFrame = {}

local specId = nil
AUDIOQS.hushMode = AUDIOQS.HUSHMODE_OFF
local prevHushMode
--
------ /AddOn variables --
--
-- /Initialization --

--- Funcs --
--
local UpdateSpecializationInfo

-- TODO SLOW
-------------- FreshEventForFrame()
local function FreshEventForFrame(event)
	local currTime = GetTime()
	local frameSeen = customEventFrameTimestamp == currTime
	if not frameSeen then
		customEventFrameTimestamp = currTime
		for k,_ in pairs(customEventsRegisteredThisFrame) do
			customEventsRegisteredThisFrame[k] = false
		end
	end
	if customEventsRegisteredThisFrame[event] ~= true then
		customEventsRegisteredThisFrame[event] = true
		return true
	end
	return false
end

function AUDIOQS.ReregisterEvents()
	UpdateSpecializationInfo(nil, nil, "reregister")
end
--
-- /Funcs --

--- Event Funcs --
--
---- TODO, juvinile frame naming throughout, copy STATRACK name format.
local Frame_SpellUpdateCooldown = CreateFrame("Frame", "Spell Update Charges")
local Frame_CombatLog = CreateFrame("Frame", "Combat Log")
local Frame_UnitAura = CreateFrame("Frame", "Unit Aura")
local Frame_CustomEvents = CreateFrame("Frame", "Custom Events")
local Frame_LoadOrSpecChange = CreateFrame("Frame", "Load or Spec Change")
local Frame_LoadingScreen = CreateFrame("Frame", "Loading Screen Check")

local function AnyEventsRegistered()
	return Frame_SpellUpdateCooldown:IsEventRegistered("SPELL_UPDATE_COOLDOWN") or Frame_CombatLog:IsEventRegistered("COMBAT_LOG_EVENT_UNFILTERED") or Frame_UnitAura:IsEventRegistered("UNIT_AURA")
end

-------------- UnregisterEvents()
local function UnregisterEvents()
	Frame_CombatLog:UnregisterAllEvents()
	Frame_SpellUpdateCooldown:UnregisterAllEvents()
	Frame_UnitAura:UnregisterAllEvents()
	AUDIOQS.GSI_UnregisterCustomEvents(Frame_CustomEvents)
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Prompt tracking disabled.") end
end

-------------- RegisterEvents()
local function RegisterEvents()
	if AnyEventsRegistered() then -- Provides safety for changing specs. Often better to just clean-up because this should be rarely called. Spurious PLAYER_SPECIALIZATION_CHANGED (player joins raid) events need to be filtered in UpdateSpecializationInfo()
		UnregisterEvents()
	end
	
	Frame_SpellUpdateCooldown:RegisterEvent("SPELL_UPDATE_COOLDOWN")
	Frame_SpellUpdateCooldown:RegisterEvent("SPELL_UPDATE_CHARGES")
	Frame_SpellUpdateCooldown:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
	Frame_UnitAura:RegisterEvent("UNIT_AURA")
	Frame_CombatLog:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	Frame_LoadingScreen:RegisterEvent("LOADING_SCREEN_ENABLED")
	Frame_LoadingScreen:RegisterEvent("LOADING_SCREEN_DISABLED")
	AUDIOQS.GSI_RegisterCustomEvents(Frame_CustomEvents)
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Prompt tracking enabled.") end
end

-------------- UpdateSpecializationInfo()
UpdateSpecializationInfo = function(_, event, ...)
	local args = {...}
	
	local newSpecId = AUDIOQS.GetSpecId()
	local eventsWereRegistered = AnyEventsRegistered()
	
	if args then
		if args[1] == "reregister" and AUDIOQS.SpecHasPrompts(AUDIOQS.GetSpecId()) then
			RegisterEvents()
		end
	end

	if specId == newSpecId then
		return
	end
	
	specId = newSpecId
	local specHasPrompts = AUDIOQS.SpecHasPrompts(newSpecId)
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Spec #"..newSpecId.." has "..(specHasPrompts == true and "" or "no ").."available prompts.") end
	local success, err = pcall(AUDIOQS.LoadSpecialization)
	if not success then AUDIOQS.HandleError(err, "UpdateSpecializationInfo()", "AUDIOQS.LoadSpecialization()") end -- More robust coverage
	
	if specHasPrompts then
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Loaded spec "..specId) end
		RegisterEvents()
	elseif eventsWereRegistered then
if AUDIOQS.DEBUG then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."Turning off AudioQs") end
		UnregisterEvents()
	end
end	

if AUDIOQS.WOW_SPECS_IMPLEMENTED then Frame_LoadOrSpecChange:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED") end
--Frame_LoadOrSpecChange:RegisterEvent("PLAYER_LOGIN") -- TODO: Was this just naive, or some weird interaction?
Frame_LoadOrSpecChange:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame_LoadOrSpecChange:SetScript("OnEvent", function(_, event, ...) UpdateSpecializationInfo(_, event, ...) end)

Frame_CombatLog:SetScript("OnEvent",
	function(_, _, ...)
		local success, err = pcall(AUDIOQS.ProcessCombatLogForPrompts)
		if not success then AUDIOQS.HandleError(err, "CombatLogOnEvent", "AUDIOQS.ProcessCombatLogForPrompts()") end
	end
)

Frame_SpellUpdateCooldown:SetScript("OnEvent",
	function(_, _, ...)
		local success, err = pcall(AUDIOQS.ProcessSpellCooldownsForPrompts)
		if not success then AUDIOQS.HandleError(err, "SpellUpdateCooldownOnEvent()", "AUDIOQS.ProcessSpellCooldownsForPrompts()") end
	end
)

-- Optimize for already completed checks, no further spell prompts possible, etc.
Frame_UnitAura:SetScript("OnEvent",
	function(_, _, ...)
		local unitId = ...
		
		if not AUDIOQS.UnitIsIncluded(unitId) then
			return
		end
		if specId ~= nil then
		-- Abstract into class file funcs
			local aura
			for n = 1, 40, 1 do
				aura = AUDIOQS.LoadAura(unitId, n)
				if aura[AUDIOQS.UNIT_AURA_SPELL_ID] ~= nil then 
					local success, err = pcall(AUDIOQS.FindPromptsFromUnitAura, aura, unitId)
					if not success then AUDIOQS.HandleError(err, "UnitAuraOnEvent()", "AUDIOQS.FindPromptsFromUnitAura()") break end
				else
					break 
				end
			end	
		end
	end
)

Frame_CustomEvents:SetScript("OnEvent",
	function(_, event, ...)
		if not FreshEventForFrame(event) then return end
		AUDIOQS.PerformanceStart("event", false)
		local success, err = pcall(AUDIOQS.ProcessCustomEventForPrompts, event, ...)
		if not success then AUDIOQS.HandleError(err, "CustomEventsOnEvent()", "AUDIOQS.ProcessCustomEventForPrompts()") end
		AUDIOQS.PerformanceEnd("event")
	end
)

Frame_LoadingScreen:SetScript("OnEvent",
	function(_, event, ...)
		if AUDIOQS.hushMode ~= AUDIOQS.HUSHMODE_LOADINGSCREEN then
			prevHushMode = AUDIOQS.hushMode
		end
		if event == "LOADING_SCREEN_ENABLED" then
			AUDIOQS.hushMode = AUDIOQS.HUSHMODE_LOADINGSCREEN
		elseif event == "LOADING_SCREEN_DISABLED" then
			AUDIOQS.hushMode = prevHushMode
		end
	end
)
--
-- /Event Funcs --
