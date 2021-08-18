-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

-- Dev note: Doing a copy of the PetMonitor config behaviour, rather than considering making it an... well... extension-typed interface. Rather than, at 6AM, think of the efficacy, extensibility, and future of AudioQs when I could just ctrl+c, ctrl+v. But here I am, making note that this is not a decision of code-design, rather a result of being on my first Bushells.

local AUDIOQS = AUDIOQS_4Q5
local GameState = AUDIOQS.GS

local extName = "ManaMonitor"
local extNameDetailed = "Mana Monitor"
local extShortNames = "mana|mm|manamonitor|manatrack|manatracker"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED
local ext_ref_num

local extensionSpecifier = AUDIOQS.extensionColour.."<ManaMonitor>|r: "

-- Extension Variables --
--
AUDIOQS.GS.POWER_TYPE_PET = 0
 -- One second prevention of repeated prompts 

AUDIOQS.GS.MANA_MONITOR_MIN_DELAY = 3.5 -- N.b. numberical call-out will be accurate at final segment time.
AUDIOQS.GS.MANA_MONITOR_ANNOUNCING_THRESHOLD = nil
AUDIOQS.GS.MANA_MONITOR_PREV_PROMPT_TIMESTAMP = 0

local MAX_ARGS = 6
local MAX_NUMERICAL_ARGS = 6
local MIN_ARGS = 2

local CONFIG__mana_thresholds = {10, 25, 50, 100} -- Default, overridden by /aq mm [n1 n2 ... n5]
local CONFIG__threshold_strs
local CONFIG__recall_limit = 5 -- Do not call the same number twice within 3.5 seconds, unless it is lost mana.
local CONFIG__muted
local CONFIG__call_exact_res = true

local prev_threshold_index = 1
local prev_callout_index = 1
local next_recall_allowed = GetTime()

local death_detected = false
local resurrect_requested = false

local UnitMana = UnitMana
local UnitManaMax = UnitManaMax
--
-- /Extension Variables


AUDIOQS.GS.POWER_TYPE_MANA = 0
 -- Six second prevention of repeated prompts 
 -- TODO nb. drinking mage food restores 10% mana every 2 seconds .'. drinking from below 10% and up will prompt "10", but not "20". Fix is checking for eating buff every UNIT_POWER_UPDATE... >8(
AUDIOQS.GS.MANA_MONITOR_MIN_DELAY = 6.0
AUDIOQS.GS.MANA_MONITOR_ANNOUNCING_SEG = nil
AUDIOQS.GS.MANA_MONITOR_PREV_PROMPT_TIMESTAMP = 0

 -- Default 50-100%. Expressed as a integer %age for easy comparisons when determining if e.g. mana is decreasing to 20-49 (call 50), or increasing to 20-49 (call 20) .'. avoid using flags for this.
local currentManaSegment = 50
local previousSegmentCallout = 0
--
-- /Extension Variables

local extSpells, extEvents, extSegments

local t_delims_info = {{}, {}}
local t_delims_funcs = t_delims_info[AUDIOQS.DELIM_I_FUNCS]
local t_delims_parameters = t_delims_info[AUDIOQS.DELIM_I_PARAMS]

local function premake_threshold_strs()
	CONFIG__threshold_strs = {}
	local thresholds = CONFIG__mana_thresholds
	local i=1
	while(i<=#thresholds) do
		CONFIG__threshold_strs[i] = string.format(
				"%sNumerical/Kendra/%s.ogg", AUDIOQS.SOUNDS_ROOT, thresholds[i]
			)
		i=i+1
	end
end
premake_threshold_strs()

local function save_threshold_settings(thresholdsTbl)
	table.sort(thresholdsTbl)
	-- remove duplicates
	local previousNum = -1
	local i=1 while(i<=#thresholdsTbl) do
		if previousNum and previousNum == thresholdsTbl[i] then
			previousNum = thresholdsTbl[i]
			table.remove(thresholdsTbl, i)
		else
			i=i+1
		end
	end
	-- print the saved thresholds
	local thresholdsStrTbl = {thresholdsTbl[1]}
	local n=2
	local i=2
	while(n<=#thresholdsTbl) do
		thresholdsStrTbl[i] = ", "
		thresholdsStrTbl[i+1] = thresholdsTbl[n]
		n=n+1
		i=i+2
	end
	print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Setting mana thresholds to:\n"..
			"  "..table.concat(thresholdsStrTbl))
	-- save
	SV_Specializations["ManaMonitorThresholds"] = thresholdsTbl
	CONFIG__mana_thresholds = thresholdsTbl
	premake_threshold_strs()
end

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
				return {spells=extSpells, events=extEvents, segments=extSegments, extNum=ext_ref_num}
			end,
		["SpecAllowed"] = function(specId) 
				if extSpecLimit == AUDIOQS.ANY_SPEC_ALLOWED or extSpecLimit == specId then
					return true
				end 
			end,
		["GetDelimInfo"] = function() return t_delims_info end,
		["Initialize"] = function()
				if SV_Specializations["ManaMonitorThresholds"] then
					save_threshold_settings(SV_Specializations["ManaMonitorThresholds"])
					CONFIG__call_exact_res = SV_Specializations["ManaMonitorCallRes"] or true
				end
				AUDIOQS.ManaMonitor_UpdateManaSegment()
				if not AUDIOQS.Util_SlashCmdExists("mm") then
					AUDIOQS.Util_RegisterSlashCmd("mm", function(args)
							local numArgs = #args
							for i=1,numArgs do
								args[i] = string.lower(args[i])
							end
							
							-- Check for a valid mana threshold entry
							local numericalCheck = false
							local thresholds = {}
							if numArgs>=MIN_ARGS and numArgs<=MAX_NUMERICAL_ARGS then
								local i=MIN_ARGS
								while(1) do
									local numerical = tonumber(args[i])
									if type(numerical) ~= "number" then
										if i>MIN_ARGS then
											print(AUDIOQS.audioQsSpecifier..extensionSpecifier..
													"Alphabetical found after a numerical argument, printing usage...")
											args[2] = nil
										end
										break; -- Assuming a help / mute / unmute cmd
									elseif numerical < 5 or numerical > 100 or numerical%5 ~= 0 then
										print(AUDIOQS.audioQsSpecifier..extensionSpecifier..
													"Threshold "..numerical.." must be [5, 10, ..., 95, 100], printing usage...")
										args[2] = nil -- threshold out-of-bounds, print usage
										break;
									end
									table.insert(thresholds, numerical)
									if i>=numArgs then
										numericalCheck = true
										break;
									end
									i=i+1
								end
							end

							-- run cmd
							if numericalCheck then
								save_threshold_settings(thresholds)
							elseif not args[2] or args[2] == "-h" or string.match(args[2], ".*help.*") then
								-- Print -h
								print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Usage:\n"..
										"Mana thresholds: \"/aq mm 50\" -- between 1 and 5 entries.\n"..
										"Mana thresholds: \"/aq mm 10 25 40 70 100\" -- divisible by 5.\n"..
										"Temporary mute: \"/aq mm mute\" \"/aq mm unmute\"\n"..
										"Disable on-resurrect mana call: /aq mm res off")
								return
							elseif args[2] == "off" or args[2] == "mute" then
								CONFIG__muted = true
								print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Off.")
							elseif args[2] == "on" or args[2] == "unmute" then
								CONFIG__muted = false
								print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."On.")
							elseif args[2] == "res" or args[2] == "rez" or args[2] == "resurrect" then
								if args[3] == "on" or args[3] == "unmute" then
									CONFIG__call_exact_res = true
									SV_Specializations["ManaMonitorCallRes"] = true
									print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."On-resurrect mana call-out enabled.")
								elseif args[3] == "off" or args[3] == "mute" then
									CONFIG__call_exact_res = false
									SV_Specializations["ManaMonitorCallRes"] = false
									print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."On-resurrect mana call-out disabled.")
								end
							else
								return -- Don't reset the functional strings for exploding more/less code into the prompt segments, because we haven't changed anything
							end
							AUDIOQS.SEGLIB_ReloadExtDefaults(ext_ref_num)
						end)
					AUDIOQS.Util_RegisterSlashCmdSynonym("mana", "mm")
					AUDIOQS.Util_RegisterSlashCmdSynonym("mm", "mm")
					AUDIOQS.Util_RegisterSlashCmdSynonym("manamonitor", "mm")
					AUDIOQS.Util_RegisterSlashCmdSynonym("manatrack", "mm")
					AUDIOQS.Util_RegisterSlashCmdSynonym("manatracker", "mm")
				end
			end
}

--- Spell Tables and Prompts --
--
extSpells = { 
}

extEvents = {
	["UNIT_POWER_UPDATE"] = {
	},
	["RESURRECT_REQUEST"] = {
	}
}

local function cancel_prompt_if_muted(isStartFunc)
	if CONFIG__muted then
		return not isStartFunc
	end
	return not isStartFunc and false or AUDIOQS.DELIM_NO_CONCAT -- Stop func has no stop cond when unmuted
end

t_delims_funcs["%%1"] = cancel_prompt_if_muted; t_delims_parameters["%%1"] = {true}
t_delims_funcs["%%2"] = cancel_prompt_if_muted; t_delims_parameters["%%2"] = {false}
extSegments = {
	["UNIT_POWER_UPDATE"] = { 
		{
			{
				"%%1 return AUDIOQS_4Q5.ManaMonitor_UpdateManaSegment(1)",
				"%%2"
			},
			{
				0.18,
				AUDIOQS.SOUNDS_ROOT..'Numerical/Kendra/mana.ogg',
				nil,
				true
			},
			{
				0.75,
				function() local announce_fpth = CONFIG__threshold_strs[select(2, AUDIOQS.ManaMonitor_UpdateManaSegment(3))] announcing_ends = GetTime() + 0.75 return announce_fpth end,
				nil,
				true
			}
		}
	},
	["RESURRECT_REQUEST"] = {
		{
			{
				function() resurrect_requested = true return false end,
				false,
			},
			{
				nil,
				nil,
				nil,
				false
			},
		}
	},
}
--
-- /Spell Tables and Rules

--- Funcs --
--
local function round_up_5(manaPercent)
	manaPercent = floor(manaPercent)
	while(manaPercent % 5 ~= 0) do
		manaPercent = manaPercent + 1
	end
	return min(100, manaPercent)
end
------ Returns a flag if a prompt is intended.
-------- AUDIOQS.ManaMonitor_UpdateManaSegment()
function AUDIOQS.ManaMonitor_UpdateManaSegment(fromSegment)
	if UnitIsDeadOrGhost("player") then
		death_detected = true
		return false
	elseif CONFIG__call_exact_res and death_detected and (true or resurrect_requested) then -- Call-out mana, just incase brez was improved / lesser type rez
		-- Call out mana
		if fromSegment == 3 then
			death_detected = false
			resurrect_requested = false
			next_recall_allowed = GetTime() + CONFIG__recall_limit
			CONFIG__threshold_strs[0] = string.format(
					"%sNumerical/Kendra/%s.ogg", 
					AUDIOQS.SOUNDS_ROOT, 
					round_up_5(
							UnitPower("player", AUDIOQS.GS.POWER_TYPE_MANA) 
								/ UnitPowerMax("player", AUDIOQS.GS.POWER_TYPE_MANA)
								* 100
						)
				)
		end
		return true, 0
	end
	
	local playerMana = UnitPower("player", AUDIOQS.GS.POWER_TYPE_MANA) / UnitPowerMax("player", AUDIOQS.GS.POWER_TYPE_MANA) * 100
	local manaDecreasing = playerMana < currentManaSegment
	local thresholds = CONFIG__mana_thresholds
	local prevThresholdIndex = prev_threshold_index
	
	-- less than lowest
	if playerMana < thresholds[1] then
		if prevThresholdIndex ~= 0 then
			prev_threshold_index = 0
			prev_callout_index = 1
			return true, 1
		end
		return false, prev_callout_index
	end
	for i=1,#thresholds do
		-- find segment, set prev_threshold_index to the lower threshold of the segment, set the true callout
		if playerMana >= thresholds[i] and playerMana < (thresholds[i+1] or 101) then
			local thisThreshold = thresholds[i]
			local manaLost = playerMana < (thresholds[prevThresholdIndex] or 0)
			if i ~= prevThresholdIndex
					and (
						--[[manaLost or ]]abs(prev_callout_index - i)>=2 or next_recall_allowed < GetTime()
					) then
				next_recall_allowed = GetTime() + CONFIG__recall_limit
				prev_threshold_index = i
				prev_callout_index = manaLost and min(#thresholds, i+1) or i
				return true, prev_callout_index -- highest thresh may be <100.
			end
			break;
		end
	end
	return false, prev_callout_index -- We may be about to stage to the number-call out segment
end

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
ext_ref_num = AUDIOQS.RegisterExtension(extName, extFuncs)