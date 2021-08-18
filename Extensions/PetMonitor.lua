-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

-- Code is CTRL+C, CTRL+V of Mana Monitor, it needs to be in it's own extension because loading all of HealthMonitor is a poor choice due to it's abstractions built around the idea of 5-man parties and top-3 lowest callout for raids. Also this is intended to be kinda final. If more wild requests appear (who knows if the visually-impaired community grows, I just hope they're having fun, and feel enabled), a further abstraction might be necessary, but it's not the direction I envisioned.

local AUDIOQS = AUDIOQS_4Q5
local GameState = AUDIOQS.GS

local extName = "PetMonitor"
local extNameDetailed = "Pet Monitor -- For pet health alerts"
local extShortNames = "pm|pethealth|pettrack|pettracker|pethealthmonitor|pethealthtrack|pethealthtracker"
local extSpecLimit = AUDIOQS.ANY_SPEC_ALLOWED
local ext_ref_num

local extensionSpecifier = AUDIOQS.extensionColour.."<PetMonitor>|r: "

-- Extension Variables --
--
AUDIOQS.GS.POWER_TYPE_PET = 0
 -- One second prevention of repeated prompts 

AUDIOQS.GS.PET_MONITOR_MIN_DELAY = 1.3 -- N.b. numberical call-out will be accurate at final segment time.
AUDIOQS.GS.PET_MONITOR_ANNOUNCING_THRESHOLD = nil
AUDIOQS.GS.PET_MONITOR_PREV_PROMPT_TIMESTAMP = 0

local MAX_ARGS = 6
local MAX_NUMERICAL_ARGS = 6
local MIN_ARGS = 2

local CONFIG__health_thresholds = {0, 25, 50, 90} -- Default, overridden by /aq pm [n1 n2 ... n5]
local CONFIG__threshold_strs
local CONFIG__recall_limit = 3.5 -- Do not call the same number twice within 3.5 seconds, unless it is lost health.
local CONFIG__muted

local prev_threshold_index = 1
local prev_callout_index = 1
local next_recall_allowed = GetTime()
local death_processed = false

local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsDead = UnitIsDead
--
-- /Extension Variables

local extSpells, extEvents, extSegments

local t_delims_info = {{}, {}}
local t_delims_funcs = t_delims_info[AUDIOQS.DELIM_I_FUNCS]
local t_delims_parameters = t_delims_info[AUDIOQS.DELIM_I_PARAMS]

local function premake_threshold_strs()
	CONFIG__threshold_strs = {}
	local thresholds = CONFIG__health_thresholds
	local i=1
	if thresholds[i] == 0 then
		CONFIG__threshold_strs[i] = string.format("%sNumerical/Kendra/dead.ogg", AUDIOQS.SOUNDS_ROOT)
		i=i+1
	end
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
	print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Setting health thresholds to:\n"..
			"  "..table.concat(thresholdsStrTbl))
	-- save
	SV_Specializations["PetMonitorThresholds"] = thresholdsTbl
	CONFIG__health_thresholds = thresholdsTbl
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
				if SV_Specializations["PetMonitorThresholds"] then
					save_threshold_settings(SV_Specializations["PetMonitorThresholds"])
				end
				AUDIOQS.PetMonitor_UpdateHealthSegment()
				if not AUDIOQS.Util_SlashCmdExists("pm") then
					AUDIOQS.Util_RegisterSlashCmd("pm", function(args)
							local numArgs = #args
							for i=1,numArgs do
								args[i] = string.lower(args[i])
							end
							
							-- Check for a valid health threshold entry
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
									elseif numerical < 0 or numerical > 100 or numerical%5 ~= 0 then
										print(AUDIOQS.audioQsSpecifier..extensionSpecifier..
													"Threshold "..numerical.." must be [0, 5, 10, ..., 95, 100], printing usage...")
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
										"Health thresholds: \"/aq pm 50\" -- between 1 and 5 entries.\n"..
										"Health thresholds: \"/aq pm 10 25 40 70 100\" -- divisible by 5.\n"..
										"Temporary mute: \"/aq pm mute\" \"/aq hm unmute\"")
								return
							elseif args[2] == "off" or args[2] == "mute" then
								CONFIG__muted = true
								print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."Off.")
							elseif args[2] == "on" or args[2] == "unmute" then
								CONFIG__muted = false
								print(AUDIOQS.audioQsSpecifier..extensionSpecifier.."On.")
							else
								return -- Don't reset the functional strings for exploding more/less code into the prompt segments, because we haven't changed anything
							end
							AUDIOQS.SEGLIB_ReloadExtDefaults(ext_ref_num)
						end)
					AUDIOQS.Util_RegisterSlashCmdSynonym("petmonitor", "pm")
					AUDIOQS.Util_RegisterSlashCmdSynonym("pethealth", "pm")
					AUDIOQS.Util_RegisterSlashCmdSynonym("pethealthmonitor", "pm")
					AUDIOQS.Util_RegisterSlashCmdSynonym("pettrack", "pm")
					AUDIOQS.Util_RegisterSlashCmdSynonym("pettracker", "pm")
				end
			end
}

--- Spell Tables and Prompts --
--


extSpells = { 
}

extEvents = {
	["UNIT_HEALTH"] = {
	},
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
	["UNIT_HEALTH"] = {
		{
			{
				"%%1 return AUDIOQS_4Q5.PetMonitor_UpdateHealthSegment(1)",
				"%%2"
			},
			{
				0.22,
				AUDIOQS.SOUNDS_ROOT..'Numerical/Kendra/pet.ogg',
				nil,
				true
			},
			{
				0.75,
				function() local announce_fpth = CONFIG__threshold_strs[select(2, AUDIOQS.PetMonitor_UpdateHealthSegment(3))] announcing_ends = GetTime() + 0.75 return announce_fpth end,
				nil,
				true
			}
		}
	}
}
--
-- /Spell Tables and Rules

--- Funcs --
--
------ Returns a flag if a prompt is intended.
-------- AUDIOQS.PetMonitor_UpdateHealthSegment()
function AUDIOQS.PetMonitor_UpdateHealthSegment(fromSegment)
	local petHealth = 100 * UnitHealth("pet") / UnitHealthMax("pet")
	local thresholds = CONFIG__health_thresholds
	local prevThresholdIndex = prev_threshold_index
	
	if UnitIsDead("pet") then
		if fromSegment == 1 and not death_processed and prev_callout_index ~= 1 and thresholds[1] == 0 then
			prev_threshold_index = 1
			prev_callout_index = 1
			death_processed = true
			return true, prev_callout_index
		end
		return false, prev_callout_index
	else
		if death_processed then -- The pet was rezzed
			prev_threshold_index = #thresholds
			prev_callout_index = #thresholds
			death_processed = false
			return false, prev_threshold_index
		end
		-- less than lowest
		if petHealth < thresholds[1] then
			if prevThresholdIndex ~= 0 then
				prev_threshold_index = 0
				prev_callout_index = 1
				return true, 1
			end
			return false, prev_callout_index
		end
	end
	for i=1,#thresholds do
		-- find segment, set prev_threshold_index to the lower threshold of the segment, set the true callout
		if petHealth >= thresholds[i] and petHealth < (thresholds[i+1] or 101) then
			local thisThreshold = thresholds[i]
			local healthLost = petHealth < (thresholds[prevThresholdIndex] or 0)
			if i ~= prevThresholdIndex
					and (
						healthLost or abs(prev_callout_index - i)>=2 or next_recall_allowed < GetTime()
					) then
				next_recall_allowed = GetTime() + CONFIG__recall_limit
				prev_threshold_index = i
				prev_callout_index = healthLost and min(#thresholds, i+1) or i
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