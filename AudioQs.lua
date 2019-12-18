-- All code written and maintained by Yewchi 
-- Thanks to Slyckety and others for helping with test. Couldn't do this without the help!
-- zyewchi@gmail.com

AQ = {}

AQ.DEBUG = false
AQ.VERBOSE = AQ.DEBUG and true

AQ.WOW_CLASSIC = (select(4, GetBuildInfo()) < 20000) -- Can this be more broadly determined?

--- Initialization --
--
------- Filenames --
--
AQ.AUDIOQS_ROOT = 		"Interface/AddOns/AudioQs/"
AQ.SOUNDS_ROOT = 		AQ.AUDIOQS_ROOT.."Sounds/"
--
------ /Filenames --

------- Flags --
--
AQ.SPELL_TYPE_ABILITY = 								0xFFF0 -- Type of a spell which is to be checked
AQ.SPELL_TYPE_AURA = 									0xFFF1

AQ.SPEC_NOT_IMPLEMENTED =								0xFFFF -- Nothing exists in AudioQs.lua WTF file

AQ.ANY_SPEC_ALLOWED =									0xFFF0 -- For loading Extensions
AQ.ONE_SPEC_ALLOWED = 									0xFFF1
--
------ /Flags --

------- Table key references --
--
AQ.SPELL_SPELL_NAME = 1
AQ.SPELL_CHARGES = 2
AQ.SPELL_DURATION = 3
AQ.SPELL_EXPIRATION = 4
AQ.SPELL_UNIT_ID = 5
AQ.SPELL_SPELL_TYPE = 6

AQ.UNIT_AURA_NAME = 1
AQ.UNIT_AURA_COUNT = 3
AQ.UNIT_AURA_DEBUFF_TYPE = 4
AQ.UNIT_AURA_DURATION = 5
AQ.UNIT_AURA_EXPIRATION = 6
AQ.UNIT_AURA_UNIT_ID = 7
AQ.UNIT_AURA_SPELL_ID = 10
AQ.UNIT_AURA_TIME_MOD = 15 -- always = 1. For prelim confirmation of a valid aura

AQ.SPEC_INFO_NUM = 1
AQ.SPEC_INFO_NAME = 2
AQ.UNIT_CLASS_NUM = 3

AQ.CLC_PLAYERLOCATION_NAME = 1
AQ.CLC_PLAYERLOCATION_CLASS_ID = 3
--
------ /Table key references --

------- Static vals --
--
AQ.PLAYER_GUID = UnitGUID("player")
AQ.SPELLID_GCD = 61304
AQ.HUSHMODE_OFF = 									0x0
AQ.HUSHMODE_USER = 									0xFFF0
AQ.HUSHMODE_LOADINGSCREEN = 						0xFFF1
--
------- /Static vals --

------- Return values --
--
AQ.SPELLS_SPELL_NOT_LISTED = 							0xFFF0
--
------ /Return values --

------- AddOn variables --
--
local customEventFrameTimestamp = 0
local customEventsRegisteredThisFrame = {}

local specId = nil
AQ.hushMode = AQ.HUSHMODE_OFF
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

function AQ.ReregisterEvents()
	UpdateSpecializationInfo(nil, nil, "reregister")
end
--
-- /Funcs --

--- Event Funcs --
--
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
	AQ.GSI_UnregisterCustomEvents(Frame_CustomEvents)
if AQ.DEBUG then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."Prompt tracking disabled.") end
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
	AQ.GSI_RegisterCustomEvents(Frame_CustomEvents)
if AQ.DEBUG then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."Prompt tracking enabled.") end
end

-------------- UpdateSpecializationInfo()
UpdateSpecializationInfo = function(_, event, ...)
	local args = {...}
	
	local newSpecId = AQ.GetSpec()
	local eventsWereRegistered = AnyEventsRegistered()
	
	if args then
		if args[1] == "reregister" and AQ.SpecHasPrompts(AQ.GetSpec()) then
			RegisterEvents()
		end
	end
	
	if specId == newSpecId then
		return
	end
	
	specId = newSpecId
	local specHasPrompts = AQ.SpecHasPrompts(newSpecId)
if AQ.DEBUG then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."Spec #"..newSpecId.." has "..(specHasPrompts == true and "" or "no ").."available prompts.") end
	AQ.LoadSpecialization()
	success = true
	--local success, err = pcall(AQ.LoadSpecialization)
	if not success then AQ.HandleError(err, "UpdateSpecializationInfo()", "AQ.LoadSpecialization()") end -- More robust coverage
	
	if specHasPrompts then
if AQ.DEBUG then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."Loaded spec "..specId) end
		RegisterEvents()
	elseif eventsWereRegistered then
if AQ.DEBUG then print(AQ.audioQsSpecifier..AQ.debugSpecifier.."Turning off AudioQs") end
		UnregisterEvents()
	end
end	
if not AQ.WOW_CLASSIC then Frame_LoadOrSpecChange:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED") end
--Frame_LoadOrSpecChange:RegisterEvent("PLAYER_LOGIN") -- TODO: Was this just naive, or some weird interaction?
Frame_LoadOrSpecChange:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame_LoadOrSpecChange:SetScript("OnEvent", function(_, event, ...) UpdateSpecializationInfo(_, event, ...) end)

Frame_CombatLog:SetScript("OnEvent",
	function(_, _, ...)
		local success, err = pcall(AQ.ProcessCombatLogForPrompts)
		if not success then AQ.HandleError(err, "CombatLogOnEvent", "AQ.ProcessCombatLogForPrompts()") end
	end
)

Frame_SpellUpdateCooldown:SetScript("OnEvent",
	function(_, _, ...)
		local success, err = pcall(AQ.ProcessSpellCooldownsForPrompts)
		if not success then AQ.HandleError(err, "SpellUpdateCooldownOnEvent()", "AQ.ProcessSpellCooldownsForPrompts()") end
	end
)

-- Optimize for already completed checks, no further spell prompts possible, etc.
Frame_UnitAura:SetScript("OnEvent",
	function(_, _, ...)
		local unitId = ...
		
		if not AQ.UnitIsIncluded(unitId) then
			return
		end
		if specId ~= nil then
		-- Abstract into class file funcs
			local aura
			for n = 1, 40, 1 do
				aura = AQ.LoadAura(unitId, n, "HELPFUL")
				if aura[AQ.UNIT_AURA_SPELL_ID] ~= nil then 
					local success, err = pcall(AQ.FindPromptsFromUnitAura, aura)
					if not success then AQ.HandleError(err, "UnitAuraOnEvent()", "AQ.FindPromptsFromUnitAura()") break end
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

		--print("Event starting ProcessCustomEventForPrompts() is "..event)
		local success, err = pcall(AQ.ProcessCustomEventForPrompts, event, ...)
		if not success then AQ.HandleError(err, "CustomEventsOnEvent()", "AQ.ProcessCustomEventForPrompts()") end
	end
)

Frame_LoadingScreen:SetScript("OnEvent",
	function(_, event, ...)
		if AQ.hushMode ~= AQ.HUSHMODE_LOADINGSCREEN then
			prevHushMode = AQ.hushMode
		end
		if event == "LOADING_SCREEN_ENABLED" then
			AQ.hushMode = AQ.HUSHMODE_LOADINGSCREEN
		elseif event == "LOADING_SCREEN_DISABLED" then
			AQ.hushMode = prevHushMode
		end
	end
)
--
-- /Event Funcs --
