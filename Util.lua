-- All code written and maintained by Yewchi 
-- zyewchi@gmail.com

local AUDIOQS = AUDIOQS_4Q5

------- Error Codes --
--
AUDIOQS.ERR_UNKNOWN =										0xEFF0
AUDIOQS.ERR_INVALID_ARGS = 									0xEFF1
AUDIOQS.ERR_UNEXPECTED_RETURN_VALUE =						0xEFF2
AUDIOQS.ERR_UNKNOWN_SPELL_AS_ARGUMENT = 					0xEFF3
AUDIOQS.ERR_UNKNOWN_EVENT_AS_ARGUMENT =						0xEFF4
AUDIOQS.ERR_INVALID_AURA_DATA =								0xEFF5
AUDIOQS.ERR_INVALID_SOUND_DATA = 							0xEFF6
AUDIOQS.ERR_INVALID_CONDITIONAL_RESULT =					0xEFF7
AUDIOQS.ERR_CUSTOM_FUNCTION_RUNTIME =						0xEFF8
AUDIOQS.ERR_UNIMPLEMENTED_EXTENSION_REQUIREMENTS =			0xEFF9
AUDIOQS.ERR_TABLE_COPIED_SELF_REFERENTIAL =					0xEFFA
--
------ /Error Codes --

------- Default Msgs --
--
AUDIOQS.audioQsSpecifier = "|cff50C0F0[AudioQs]".."|r "
AUDIOQS.infoSpecifier = "|cff50A0FF<INFO>".."|r: "
AUDIOQS.debugSpecifier = "|cffF080F0<DEBUG>".."|r: "
AUDIOQS.errSpecifier = "|cffC01050<ERR>".."|r: "
AUDIOQS.ERR_MSGS = { 
	[AUDIOQS.ERR_UNKNOWN] =
		AUDIOQS.audioQsSpecifier..
		AUDIOQS.errSpecifier..
		"#"..AUDIOQS.ERR_UNKNOWN.." "..
		"Unknown error.",
	[AUDIOQS.ERR_INVALID_ARGS] =
		AUDIOQS.audioQsSpecifier..
		AUDIOQS.errSpecifier..
		"#"..AUDIOQS.ERR_INVALID_ARGS.." "..
		"Invalid args.",
	[AUDIOQS.ERR_UNEXPECTED_RETURN_VALUE] =
		AUDIOQS.audioQsSpecifier..
		AUDIOQS.errSpecifier..
		"#"..AUDIOQS.ERR_INVALID_ARGS.." "..
		"An unexpected or impossible result was returned from a function.",
	[AUDIOQS.ERR_UNKNOWN_SPELL_AS_ARGUMENT] = 
		AUDIOQS.audioQsSpecifier..
		AUDIOQS.errSpecifier..
		"#"..AUDIOQS.ERR_UNKNOWN_SPELL_AS_ARGUMENT.." "..
		" An unlisted spellId was passed to a function.",
	[AUDIOQS.ERR_UNKNOWN_EVENT_AS_ARGUMENT] = 
		AUDIOQS.audioQsSpecifier..
		AUDIOQS.errSpecifier..
		"#"..AUDIOQS.ERR_UNKNOWN_SPELL_AS_ARGUMENT.." "..
		" An unlisted event was passed to a function.",
	[AUDIOQS.ERR_INVALID_AURA_DATA] = 
		AUDIOQS.audioQsSpecifier..
		AUDIOQS.errSpecifier..
		"#"..AUDIOQS.ERR_INVALID_AURA_DATA.." "..
		" Data passed to a function did not contain a valid aura table.",
	[AUDIOQS.ERR_INVALID_SOUND_DATA] = 
		AUDIOQS.audioQsSpecifier..
		AUDIOQS.errSpecifier..
		"#"..AUDIOQS.ERR_INVALID_AURA_DATA.." "..
		" Sound data retreived from a segment was neither a number nor a filepath.",
	[AUDIOQS.ERR_INVALID_CONDITIONAL_RESULT] =
		AUDIOQS.audioQsSpecifier..
		AUDIOQS.errSpecifier..
		"#"..AUDIOQS.ERR_INVALID_CONDITIONAL_RESULT.." "..
		" An invalid result was derived from a segment conditional.",
	[AUDIOQS.ERR_CUSTOM_FUNCTION_RUNTIME] = 
		AUDIOQS.audioQsSpecifier..
		AUDIOQS.errSpecifier..
		"#"..AUDIOQS.ERR_CUSTOM_FUNCTION_RUNTIME.." "..
		" Runtime error occured in CustomFunc.",
	[AUDIOQS.ERR_UNIMPLEMENTED_EXTENSION_REQUIREMENTS] =
		AUDIOQS.audioQsSpecifier..
		AUDIOQS.errSpecifier..
		"#"..AUDIOQS.ERR_UNIMPLEMENTED_EXTENSION_REQUIREMENTS.." "..
		" Extension doesn't implement all functions and/or data.",
	[AUDIOQS.ERR_TABLE_COPIED_SELF_REFERENTIAL] =
		AUDIOQS.audioQsSpecifier..
		AUDIOQS.errSpecifier..
		"#"..AUDIOQS.ERR_TABLE_COPIED_SELF_REFERENTIAL.." "..
		" Table copy will overflow"
}
AUDIOQS.extensionColour = "|cffFFA020"
AUDIOQS.STOP_ERROR_MAX_REPORTS = AUDIOQS.audioQsSpecifier.." Max errors exceeded. Stopping error reports."
--
------ /Default msgs --

------- Static vals --
--
local MAX_ERRORS_PER_SESSION = 3
local DUPLICATE_ERROR_GARBAGE_TIMER = 3.0
--
------ /Static vals --

------- AddOn variables --
--
local errorsThisSession = 0
local mostRecentErrorString = nil
local mostRecentErrorTimestamp = 0

local currentlyEvaluatingAura = {"", 0, 0, "", 0, 0, "", false, false, 0, false, false, false, false, 0}
local currentlyEvaluatingCombatLog = {0, "", false, "", "", 0, 0, "", "", 0, 0}
--
------ /AddOn variables --

------ Fast Funcs --
--
local UnitAura = UnitAura
local GetSpellCooldown = GetSpellCooldown
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
--
----- /Fast Funcs --

SLASH_AQ1 = "/aq"
SLASH_AQ2 = "/audioqs"

local Frame_OnLoadMessages = CreateFrame("Frame", "On Load Messages")
Frame_OnLoadMessages:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame_OnLoadMessages:SetScript("OnEvent", function() 
		if SV_Specializations ~= nil and SV_Specializations["nextLoadMessage"] ~= nil then
			print(SV_Specializations["nextLoadMessage"])
			SV_Specializations["nextLoadMessage"] = nil
			Frame_OnLoadMessages:SetScript("OnEvent", nil)
		end 
	end)

local AUDIOQS_SLASH_CMDS = {
	----- INSTALL -----
	["load"] = function(args)
			if args[2] == nil then
				print(AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."Please specify the extension you would like to load. '/aq load extension'")
				return
			end
			local mySpecInfo = {AUDIOQS.GetSpecId()}
			local mySpec = mySpecInfo[AUDIOQS.SPEC_INFO_NUM]
			local funcs = AUDIOQS.GetExtensionNameFuncs(args[2])
			
			if funcs == nil then
				print(AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."\""..args[2].."\" is not a known extension.\nAvailable extensions are:\n")
				local validExtNames = AUDIOQS.GetRegisteredExtensionNames()
				local validExtNamesConcat = {"|cFFC8C8FF"}
				local numExtensions = #validExtNames
				local i = 2
				for n=1,numExtensions-1 do
					validExtNamesConcat[i] = validExtNames[n]
					validExtNamesConcat[i+1] = "|r, |cFFC8C8FF"
					i = i + 2
				end
				validExtNamesConcat[i] = validExtNames[numExtensions]
				print(table.concat(validExtNamesConcat))
				return
			elseif SV_Specializations ~= nil and SV_Specializations[mySpec] ~= nil and SV_Specializations[mySpec][funcs["GetName"]()] ~= nil then
				print(AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."Extension \""..funcs["GetName"]().."\" is already installed.") -- TODO Placeholder, informative, but messy output.
				return
			end
			
			if funcs["SpecAllowed"](mySpec) then
				--- Load ext
				AUDIOQS.GSI_LoadSpecTables(mySpec, funcs)
				AUDIOQS.SetAbilityAndAuraTables(AUDIOQS.InitializePrompts(mySpec))
				AUDIOQS.ReregisterEvents()
				ReloadUI()
				SV_Specializations["nextLoadMessage"] = AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."Loaded: "..funcs["GetNameDetailed"]()
			else
				--- Spec not allowed
				print(AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."Failed! Extension \""..funcs["GetName"]().."\" is not able to be loaded for "..mySpecInfo[AUDIOQS.SPEC_INFO_NAME].." (spec "..mySpec..").")
			end
		end,
	----- REMOVE -----
	["remove"] = function(args)
			if args[2] == nil then
				print(AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."Which extension do you want to remove? '/aq remove extension'")
				return
			end
			local mySpecInfo = {AUDIOQS.GetSpecId()}
			local mySpec = mySpecInfo[AUDIOQS.SPEC_INFO_NUM]
			local extName = args[2]
			local funcs = AUDIOQS.GetExtensionNameFuncs(extName)
			if funcs == nil or SV_Specializations == nil or SV_Specializations[mySpec] == nil or SV_Specializations[mySpec][funcs["GetName"]()] == nil then
				print(AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."Extension \""..extName.."\" is not loaded.\nLoaded extensions are:\n"..AUDIOQS.PrintableTable(SV_Specializations == nil and "nil" or SV_Specializations[mySpec]))
				--AUDIOQS.GSI_RemoveExtension(mySpec, funcs["GetName"]())
			else
				if AUDIOQS.GSI_RemoveExtension(mySpec, funcs["GetName"]()) then
					--AUDIOQS.GSI_LoadSpecTables(mySpec, funcs) TODO test without reload, can't remember loading pipeline / data 100%, but preliminary tests look good
					AUDIOQS.SetAbilityAndAuraTables(AUDIOQS.InitializePrompts(mySpec))
					AUDIOQS.ReregisterEvents()
					ReloadUI()
					SV_Specializations["nextLoadMessage"] = AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."Removed: "..funcs["GetNameDetailed"]()
				else
					AUDIOQS.HandleError({code=AUDIOQS.ERR_UNEXPECTED_RETURN_VALUE}, "SlashCmdList()", "GSI_RemoveExtension("..AUDIOQS.Printable(mySpec)..", "..AUDIOQS.Printable(extName)..")")
				end
			end
		end,
	----- HUSH ON -----
	["hush"] = function(args)
			if AUDIOQS.hushMode == AUDIOQS.HUSHMODE_OFF then
				AUDIOQS.hushMode = AUDIOQS.HUSHMODE_USER
				print(AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."Hush mode on. Type \"/aq go\" in chat to enable AudioQs.")
			else
				print(AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."Hush mode is already on. Type \"/aq go\" in chat to enable AudioQs.")
			end
		end,
	----- HUSH OFF -----
	["unhush"] = function(args)
			if AUDIOQS.hushMode ~= AUDIOQS.HUSHMODE_OFF then 
				AUDIOQS.hushMode = AUDIOQS.HUSHMODE_OFF
				print(AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."Hush mode off. AudioQs has been enabled.")
			else
				print(AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."AudioQs is already enabled.")
			end
		end,
	["channel"] = function(args)
			if args[2] == nil then
				print(AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."Please specify the channel for AudioQs to use. '/aq channel master|effects|ambience|music|dialog|talking head'")
				return
			end
			AUDIOQS.ChangeAudioChannel(args[2])
		end,
	["reset"] = function(args)
			AUDIOQS.GSI_ResetAudioQs()
			ReloadUI()
			SV_Specializations["nextLoadMessage"] = AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."AudioQs set to default."
			return
		end
}
do -- Command Synonyms
	----- INSTALL ----
	AUDIOQS_SLASH_CMDS["install"] = AUDIOQS_SLASH_CMDS["load"]
	----- REMOVE ----
	AUDIOQS_SLASH_CMDS["uninstall"] = AUDIOQS_SLASH_CMDS["remove"]
	AUDIOQS_SLASH_CMDS["unload"] = AUDIOQS_SLASH_CMDS["remove"]
	----- HUSH ON ----
	AUDIOQS_SLASH_CMDS["quiet"] = AUDIOQS_SLASH_CMDS["hush"]
	AUDIOQS_SLASH_CMDS["stop"] = AUDIOQS_SLASH_CMDS["hush"]
	AUDIOQS_SLASH_CMDS["shh"] = AUDIOQS_SLASH_CMDS["hush"]
	AUDIOQS_SLASH_CMDS["off"] = AUDIOQS_SLASH_CMDS["hush"]
	----- HUSH OFF -----
	AUDIOQS_SLASH_CMDS["start"] = AUDIOQS_SLASH_CMDS["hush"]
	AUDIOQS_SLASH_CMDS["begin"] = AUDIOQS_SLASH_CMDS["hush"]
	AUDIOQS_SLASH_CMDS["go"] = AUDIOQS_SLASH_CMDS["hush"]
	AUDIOQS_SLASH_CMDS["on"] = AUDIOQS_SLASH_CMDS["hush"]
	----- CHANGE SOUND CHANNEL -----
	AUDIOQS_SLASH_CMDS["track"] = AUDIOQS_SLASH_CMDS["channel"]
	----- RESET -----
	AUDIOQS_SLASH_CMDS["default"] = AUDIOQS_SLASH_CMDS["reset"]
	AUDIOQS_SLASH_CMDS["setdefault"] = AUDIOQS_SLASH_CMDS["reset"]
end

-- SLASH COMMANDS --
SlashCmdList["AQ"] = function(msg)
	local args = AUDIOQS.SplitString(msg, "%s")
	if args ~= nil then 
 		local cmdFunc = AUDIOQS_SLASH_CMDS[string.lower(args[1])]
		if cmdFunc then
			cmdFunc(args)
		end
	else
		print(AUDIOQS.audioQsSpecifier..AUDIOQS.infoSpecifier.."Invalid command.")
	end
end

function AUDIOQS.Util_SlashCmdExists(cmdString)
	return AUDIOQS_SLASH_CMDS[cmdString] and true or false
end

function AUDIOQS.Util_RegisterSlashCmd(cmdString, func)
	AUDIOQS_SLASH_CMDS[cmdString] = func
end

function AUDIOQS.Util_RegisterSlashCmdSynonym(synonymString, cmdString)
	AUDIOQS_SLASH_CMDS[synonymString] = AUDIOQS_SLASH_CMDS[cmdString]
end

-------- AUDIOQS.GetAuraInfo()
function AUDIOQS.GetAuraInfo(unitId, spellId, spellType)
	--[[ WOW_SHADOWLANDS (not essential to rollover, but potentially a nice optimization)
	if unitId == "player" then 
		return GetPlayerAuraBySpellID(spellId)
	else ]]
		for n=1,40,1 do
			local auraSpellId = select(AUDIOQS.UNIT_AURA_SPELL_ID, UnitAura(unitId, n, spellType))
			if auraSpellId == nil then 
				return nil
			elseif auraSpellId == spellId then
				return UnitAura(unitId, n, spellType)
			end
		end
	--[[end /WOW_SHADOWLANDS ]]
end

function AUDIOQS.LoadAura(unitId, num, filter)
	currentlyEvaluatingAura[1], currentlyEvaluatingAura[2], currentlyEvaluatingAura[3], 
		currentlyEvaluatingAura[4], currentlyEvaluatingAura[5], currentlyEvaluatingAura[6], 
		currentlyEvaluatingAura[7], currentlyEvaluatingAura[8], currentlyEvaluatingAura[9],
		currentlyEvaluatingAura[10], currentlyEvaluatingAura[11], currentlyEvaluatingAura[12],
		currentlyEvaluatingAura[13], currentlyEvaluatingAura[14], currentlyEvaluatingAura[15],
		currentlyEvaluatingAura[16] 
		= UnitAura(unitId, num, filter)
		
	return currentlyEvaluatingAura
end

function AUDIOQS.LoadCombatLog()
	currentlyEvaluatingCombatLog[1], currentlyEvaluatingCombatLog[2], currentlyEvaluatingCombatLog[3],
		currentlyEvaluatingCombatLog[4], currentlyEvaluatingCombatLog[5], currentlyEvaluatingCombatLog[6],
		currentlyEvaluatingCombatLog[7], currentlyEvaluatingCombatLog[8], currentlyEvaluatingCombatLog[9],
		currentlyEvaluatingCombatLog[10], currentlyEvaluatingCombatLog[11], currentlyEvaluatingCombatLog[12],
		currentlyEvaluatingCombatLog[13], currentlyEvaluatingCombatLog[14], currentlyEvaluatingCombatLog[15],
		currentlyEvaluatingCombatLog[16], currentlyEvaluatingCombatLog[17], currentlyEvaluatingCombatLog[18],
		currentlyEvaluatingCombatLog[19], currentlyEvaluatingCombatLog[20], currentlyEvaluatingCombatLog[21],
		currentlyEvaluatingCombatLog[22], currentlyEvaluatingCombatLog[23], currentlyEvaluatingCombatLog[24]
		= CombatLogGetCurrentEventInfo()
	
	return currentlyEvaluatingCombatLog
end

function AUDIOQS.SplitString(str, splitter)
	if str == nil or splitter == nil then
		error({code=AUDIOQS.ERR_INVALID_ARGS, func="splitString(str = "..(str == nil and "nil" or str)..", splitter = "..(splitter == nil and "nil" or splitter)..")"})
	end
	local str_arr = {}
	local i = 1
	for sub in str:gmatch(string.format("[^%s]+", splitter)) do
		str_arr[i] = sub
		i = i + 1
	end
	return str_arr
end

function AUDIOQS.Print(formatString, ...)
end

function AUDIOQS.GetSpecId()
	if AUDIOQS.WOW_SPECS_IMPLEMENTED then
		return GetSpecializationInfo(GetSpecialization())
	else
		local class = {C_PlayerInfo.GetClass(PlayerLocation:CreateFromUnit("player"))}
		return class[AUDIOQS.CLC_PLAYERLOCATION_CLASS_ID], class[AUDIOQS.CLC_PLAYERLOCATION_NAME]
	end
end

function AUDIOQS.GetClassId()
	return select(3, UnitClass("player"))
end

function AUDIOQS.GetGcdDur()
	return select(2, GetSpellCooldown(AUDIOQS.SPELLID_GCD))
end

function AUDIOQS.GetGcdExpiration()
	local gcdStart, gcdDur = GetSpellCooldown(AUDIOQS.SPELLID_GCD)
	
	return gcdStart + gcdDur
end

function AUDIOQS.CopyTable(from, to, depth)
	to = {}
	for k,v in pairs(from) do
		if type(v) == "table" then
			depth = depth or 1
			if depth >= 16 then
				error({code=AUDIOQS.ERR_TABLE_COPY_SELF_REFERENTIAL, func="AUDIOQS.CopyTable("..from..", "..to..")"})
			end
			AUDIOQS.CopyTable(v, to[k], depth+1)
		else
			to[k] = v
		end
	end
end

function AUDIOQS.Printable(val)
	local t = type(val)
	if val == nil then return "nil"
	elseif t == "number" or t == "string" then return val
	elseif t == "boolean" then return (val and "true" or "false")
	elseif t == "table" then return "[tbl]"
	elseif t == "function" then return "[func]"
	elseif t == "userdata" then return "[ud]"
	elseif t == "thread" then return "[thread]"
	end
	return "[WTF]"
end

function AUDIOQS.PrintableTable(tbl, depth)
	if depth == nil then depth = 0 elseif depth > 7 then return AUDIOQS.Printable(tbl) end
	if type(tbl) ~= "table" then
		return AUDIOQS.Printable(tbl)..",\n"
	end
	local str = "{\n"
	local theseTabs = "" for i=depth,1,-1 do theseTabs = theseTabs.."  " end
	for k,v in pairs(tbl) do
		str = str..theseTabs.."["..AUDIOQS.Printable(k).."]="..AUDIOQS.PrintableTable(v, depth + 1)
	end
	return str..theseTabs.."}\n"
end

function AUDIOQS.TablePrint(tbl)
	local newLineSplit = AUDIOQS.PrintableTable(tbl)
	newLineSplit = newLineSplit:gmatch("[^\n]+")
	
	for sub in newLineSplit do
		print(sub)
	end
end

-- Will overwrite any matching keys from ammending into ammended. .'. use sparingly, and often only for conditional table creation on the moment of it's creation.
function AUDIOQS.AmmendTable(ammended, ammending)
	for k,v in pairs(ammending) do
		ammended[k] = v
	end
end

function AUDIOQS.TableEmpty(tbl)
	if tbl == nil then return true end
	for _,_ in pairs(tbl) do
		return false
	end
	return true
end

-------- AUDIOQS.LogError()
function AUDIOQS.LogError(err, parent, child, detailed)
	AUDIOQS.HandleError(err, parent, child)
	errMsg = ((err ~= nil and err.code ~= nil) and "<#"..err.code..">" or "<No ErrCode>")..".."..((parent ~= nil and parent ~= "") and parent or "???()").."->"..((child ~= nil and child ~= "") and child or "???()")..(detailed ~= nil and "..'"..detailed.."'" or "")
	
	if SV_Specializations["errorLog"] == nil then 
		SV_Specializations["errorLog"] = {} 
	end
	
	if SV_Specializations["errorLog"][1] ~= errMsg or SV_Specializations["errorLog"][2] ~= errMsg then -- TODO, was meant for simple repetition dampening, needs better agthm.
		table.insert(SV_Specializations["errorLog"], 1, errMsg)
		while (#SV_Specializations["errorLog"] > 50) do
			table.remove(SV_Specializations["errorLog"], 51) 
		end
	end
end

-- Needs automatic arguments string concats, errors need args={val1,val2}
-------- AUDIOQS.HandleError()
function AUDIOQS.HandleError(err, parent, child)
	if not AUDIOQS.DEBUG and errorsThisSession >= MAX_ERRORS_PER_SESSION then 
		return
	end
	
	if type(err) == "table" then 
		if err.code == nil then err.code = ERR_UNKNOWN end
	elseif err == nil then 
		err = {code=ERR_UNKNOWN}
	end
	
	-- Formulate full string --
	local msgGiven = (type(err) == "string" and err or "")
	local errorString = ""
	local funcString = (err.func~=nil and " func:"..err.func or ((parent~=nil and parent ~= "") and parent or "???").."->"..((child ~= nil and child ~= "") and child or "???"))
	
	if type(err.code) == "number" then 
		local errMsg = AUDIOQS.ERR_MSGS[err.code]
		errorString = (errMsg~=nil and errMsg or "[InvalidErrCode]").." "..funcString
	else
		errorString = AUDIOQS.ERR_MSGS[AUDIOQS.ERR_UNKNOWN].." "..msgGiven.." "..funcString
	end
	
	-- Check error frequency of duplicates is not too high, and print. --
	local currTime = GetTime()
	if not (errorString == mostRecentErrorString and
			currTime < mostRecentErrorTimestamp + DUPLICATE_ERROR_GARBAGE_TIMER) then
		mostRecentErrorString = errorString
		mostRecentErrorTimestamp = currTime
		
		print(errorString)
		
		errorsThisSession = errorsThisSession + 1
		if not AUDIOQS.DEBUG and errorsThisSession >= MAX_ERRORS_PER_SESSION then
			print(AUDIOQS.STOP_ERROR_MAX_REPORTS)
		end
	end
end

-- TEST (Incomplete -- Bad Refactor)
AUDIOQS.Perf = {}
AUDIOQS.CurrFrame = 0
AUDIOQS.PerfTotalMs = 0.0
local disablePerf = false -- local for safety, not consistentency
function AUDIOQS.PerformanceStart(area_str, printPerf)
	if not AUDIOQS.DEBUG or disablePerf then return end
	if AUDIOQS.Perf[area_str] == nil then
		AUDIOQS.Perf[area_str] = {{0, 0}, {0, 0}, false}
	end
	local newFrame = GetTime() > AUDIOQS.CurrFrame
	
	--UpdateAddOnMemoryUsage()
	--AUDIOQS.Perf[area_str][2][1] = GetAddOnMemoryUsage("AudioQs")
	
	if newFrame or AUDIOQS.Perf[area_str][3] == false then
		AUDIOQS.CurrFrame = GetTime()
		
		if printPerf ~= false then AUDIOQS.PerformancePrint(area_str) end
		if newFrame then
			for _, area in pairs(AUDIOQS.Perf) do
				area[3] = false
			end
		end
		AUDIOQS.Perf[area_str][3] = true
	end
	debugprofilestart()
end

function AUDIOQS.PerformanceEnd(area_str)
	local perfEndTime = debugprofilestop()
	if not AUDIOQS.DEBUG or disablePerf then return end
	local perf = AUDIOQS.Perf[area_str]
	
	--UpdateAddOnMemoryUsage()
	AUDIOQS.PerfTotalMs = AUDIOQS.PerfTotalMs + perfEndTime
	
	perf[1][2] = perf[1][2] + perfEndTime - perf[1][1]
	--UpdateAddOnMemoryUsage()
	--perf[2][2] = perf[2][2] + GetAddOnMemoryUsage("AudioQs") - perf[2][1]
end

function AUDIOQS.PerformancePrint(area_str)
	local perf = AUDIOQS.Perf[area_str]
	if not perf then print(AUDIOQS.audioQsSpecifier..AUDIOQS.debugSpecifier.."PerformancePrint(area_str): assert(DEBUG)") return end
	
	print(string.format("%s -- TotalRecordedMs:%f. ThisDesignationMs:%f. KB:%d. KB+:%d", area_str, AUDIOQS.PerfTotalMs, perf[1][2], perf[2][1], perf[2][2]))
	--print(string.format("%s -- ms:%d. KB:N/A. KB+:N/A", area_str, perf[1][2]))
end

-------- AUDIOQS.IsEqualToGcd() -- Returns if the cooldown is equal to the GCD cd, or 1.5 (some abilities trigger a GCD which is not affected by haste)
function AUDIOQS.IsEqualToGcd(cd)
	return cd == AUDIOQS.GetGcdDur() or cd == 1.5
end

-------- AUDIOQS.NilSetTable(t)
 -- For wiping non-array tables that reference other tables
function AUDIOQS.NilSetTable(t)
	for k,_ in pairs(t) do
		t[k] = nil
	end
end

local MAX_WIPE_DEPTH = 5
-------- AUDIOQS.WipeTable()
 -- This will disturb sub-table references. Should only be used for total destruction, such as re-initialization
function AUDIOQS.WipeTable(t, d)
	d = d and d+1 or 1
	for k,v in pairs(t) do
		if type(v) == "table" then
			if d <= MAX_WIPE_DEPTH then
				AUDIOQS.WipeTable(v, d)
			else
				for clearKey,_ in pairs(v) do
					v[clearKey] = nil
				end
			end
		end
		--print("wiping", k)
		t[k] = nil
	end
	AUDIOQS.RecycleTable(t)
end

recyclable_tables = {}
-------- AUDIOQS.RecycleTable()
function AUDIOQS.RecycleTable(t)
	wipe(t)
	table.insert(recyclable_tables, t)
end

-------- AUDIOQS.CreateTable()
function AUDIOQS.CreateTable()
	return table.remove(recyclable_tables) or {}
end